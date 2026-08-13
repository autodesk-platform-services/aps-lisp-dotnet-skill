// Builds the params form directly from /api/schema (da/params.schema.json) —
// no hand-invented field set. See lisp-to-dotnet SKILL.md's Step 6b.

const paramsForm = document.getElementById('paramsForm');

async function loadSchema() {
  const res = await fetch('/api/schema');
  const schema = await res.json();
  const required = new Set(schema.required || []);

  for (const [name, prop] of Object.entries(schema.properties)) {
    const wrapper = document.createElement('div');
    wrapper.className = 'field';

    const label = document.createElement('label');
    label.textContent = name + (required.has(name) ? ' *' : '');
    label.setAttribute('for', `field-${name}`);

    const input = document.createElement('input');
    input.id = `field-${name}`;
    input.name = name;

    if (prop.type === 'boolean') {
      input.type = 'checkbox';
      input.checked = prop.default ?? false;
    } else if (prop.type === 'integer' || prop.type === 'number') {
      input.type = 'number';
      if (prop.type === 'number') input.step = 'any';
      if (prop.default !== undefined) input.value = prop.default;
      if (required.has(name)) input.required = true;
    } else {
      input.type = 'text';
    }

    const small = document.createElement('small');
    small.textContent = prop.description || '';

    wrapper.append(label, input, small);
    paramsForm.appendChild(wrapper);
  }
}

loadSchema().catch((err) => {
  document.getElementById('status').textContent = `Failed to load params schema: ${err.message}`;
});

document.getElementById('runForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const status = document.getElementById('status');
  status.textContent = 'Submitting WorkItem to APS Design Automation... this can take 10-60s.';

  const formData = new FormData();
  const fileInput = document.getElementById('inputDwg');
  if (fileInput.files[0]) {
    formData.append('inputDwg', fileInput.files[0]);
  }
  for (const input of paramsForm.querySelectorAll('input')) {
    formData.append(input.name, input.type === 'checkbox' ? input.checked : input.value);
  }

  try {
    const res = await fetch('/run', { method: 'POST', body: formData });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ error: res.statusText }));
      status.textContent = `Error: ${err.error}${err.reportUrl ? `\nReport: ${err.reportUrl}` : ''}`;
      return;
    }
    const warnings = res.headers.get('X-Warnings');
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'flange-result.dwg';
    link.click();
    URL.revokeObjectURL(url);
    status.textContent = `Done — result.dwg downloaded.${warnings ? `\nWarnings: ${warnings}` : ''}`;
  } catch (err) {
    status.textContent = `Error: ${err.message}`;
  }
});
