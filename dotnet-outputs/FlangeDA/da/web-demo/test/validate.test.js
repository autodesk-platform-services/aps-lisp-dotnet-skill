'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { buildHolePatternInput, validateHolePatternInput } = require('../src/validate');

test('buildHolePatternInput coerces multipart string fields to typed values', () => {
  const input = buildHolePatternInput({
    Offset: 'true',
    FlangeTangentAngleDegrees: '30',
    PatternDiameter: '180',
    NumberOfHoles: '6',
    HoleDiameter: '18',
    CenterX: '0',
    CenterY: '0',
    RotationAngleDegrees: '15',
  });
  assert.equal(input.Offset, true);
  assert.equal(input.NumberOfHoles, 6);
  assert.equal(input.FlangeTangentAngleDegrees, 30);
  assert.equal(input.RotationAngleDegrees, 15);
});

test('buildHolePatternInput defaults Offset to true and angles to 0 when omitted', () => {
  const input = buildHolePatternInput({
    PatternDiameter: '180',
    NumberOfHoles: '6',
    HoleDiameter: '18',
    CenterX: '0',
    CenterY: '0',
  });
  assert.equal(input.Offset, true);
  assert.equal(input.FlangeTangentAngleDegrees, 0);
  assert.equal(input.RotationAngleDegrees, 0);
});

test('validateHolePatternInput rejects zero PatternDiameter', () => {
  const { errors } = validateHolePatternInput({ PatternDiameter: 0, NumberOfHoles: 6, HoleDiameter: 18, CenterX: 0, CenterY: 0 });
  assert.ok(errors.some((e) => e.includes('pcd')));
});

test('validateHolePatternInput rejects zero NumberOfHoles', () => {
  const { errors } = validateHolePatternInput({ PatternDiameter: 180, NumberOfHoles: 0, HoleDiameter: 18, CenterX: 0, CenterY: 0 });
  assert.ok(errors.some((e) => e.includes('holes')));
});

test('validateHolePatternInput rejects zero HoleDiameter', () => {
  const { errors } = validateHolePatternInput({ PatternDiameter: 180, NumberOfHoles: 6, HoleDiameter: 0, CenterX: 0, CenterY: 0 });
  assert.ok(errors.some((e) => e.includes('hole dia')));
});

test('validateHolePatternInput accepts a reasonable pattern with no warnings', () => {
  const { errors, warnings } = validateHolePatternInput({ PatternDiameter: 180, NumberOfHoles: 8, HoleDiameter: 18, CenterX: 0, CenterY: 0 });
  assert.deepEqual(errors, []);
  assert.deepEqual(warnings, []);
});

test('validateHolePatternInput warns on too many holes without treating it as an error', () => {
  const { errors, warnings } = validateHolePatternInput({ PatternDiameter: 10, NumberOfHoles: 20, HoleDiameter: 10, CenterX: 0, CenterY: 0 });
  assert.deepEqual(errors, []);
  assert.ok(warnings.includes('Too many holes??'));
});
