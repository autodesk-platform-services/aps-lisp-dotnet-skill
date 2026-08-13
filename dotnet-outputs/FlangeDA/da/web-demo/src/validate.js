'use strict';

// Mirrors FlangeDA's Models/HolePatternInput.cs (field shape) and
// Helpers/PatternValidator.cs (validation rules) so the web demo's params.json
// matches exactly what the FLANGE command expects — see ../params.schema.json.

function toBool(value) {
  return value === true || value === 'true' || value === 'on' || value === '1';
}

function toNumber(value, fallback) {
  if (value === undefined || value === '') return fallback;
  return Number(value);
}

function buildHolePatternInput(fields) {
  return {
    Offset: fields.Offset === undefined ? true : toBool(fields.Offset),
    FlangeTangentAngleDegrees: toNumber(fields.FlangeTangentAngleDegrees, 0),
    PatternDiameter: toNumber(fields.PatternDiameter, NaN),
    NumberOfHoles: parseInt(fields.NumberOfHoles, 10),
    HoleDiameter: toNumber(fields.HoleDiameter, NaN),
    CenterX: toNumber(fields.CenterX, NaN),
    CenterY: toNumber(fields.CenterY, NaN),
    RotationAngleDegrees: toNumber(fields.RotationAngleDegrees, 0),
  };
}

// Same rules as PatternValidator.cs's Validate(): required fields throw-equivalent
// (returned as errors here, since this isn't C#), "too many holes" is a warning
// only — never blocking, matching the original (info) function's actual behavior.
function validateHolePatternInput(input) {
  const errors = [];
  if (!(input.PatternDiameter > 0)) {
    errors.push('No pcd given (PatternDiameter must be > 0).');
  }
  if (!(Number.isInteger(input.NumberOfHoles) && input.NumberOfHoles > 0)) {
    errors.push('No. of holes not given (NumberOfHoles must be a positive integer).');
  }
  if (!(input.HoleDiameter > 0)) {
    errors.push('No hole dia given (HoleDiameter must be > 0).');
  }
  if (!Number.isFinite(input.CenterX) || !Number.isFinite(input.CenterY)) {
    errors.push('CenterX/CenterY must be given (pattern centre point).');
  }

  const warnings = [];
  if (errors.length === 0 && input.NumberOfHoles * input.HoleDiameter >= input.PatternDiameter * Math.PI) {
    warnings.push('Too many holes??');
  }
  return { errors, warnings };
}

module.exports = { buildHolePatternInput, validateHolePatternInput };
