import fs from 'node:fs';
import path from 'node:path';

// Preserve the licensed original. Only append rest-space kit coordinates to its glTF.
const root = path.resolve(import.meta.dirname, '..');
const source = fs.readFileSync(path.join(root, '.source/character/man-base-character-rigged.glb'));
const jsonLength = source.readUInt32LE(12);
const gltf = JSON.parse(source.subarray(20, 20 + jsonLength).toString());
const binaryOffset = 20 + jsonLength + 8;
const binary = source.subarray(binaryOffset, binaryOffset + source.readUInt32LE(20 + jsonLength));
const primitive = gltf.meshes[0].primitives[0];
const positions = gltf.accessors[primitive.attributes.POSITION];
const view = gltf.bufferViews[positions.bufferView];
const start = (view.byteOffset || 0) + (positions.byteOffset || 0);
const stride = view.byteStride || 12;
// Bake the rest-pose front-plane position (metres) into UV2. The kit shader cuts its
// panels from this per pixel, so edges stay clean regardless of vertex density.
// Rest depth goes to COLOR_0.r (z in [-0.25, 0.25] m -> [0, 1]) to tell front from back.
const restPlane = Buffer.alloc(positions.count * 12);
const depthBytes = positions.count * 8;
let minY = Infinity, maxY = -Infinity;

for (let i = 0; i < positions.count; i++) {
  const offset = start + i * stride;
  const y = binary.readFloatLE(offset + 4);
  const z = binary.readFloatLE(offset + 8);
  restPlane.writeFloatLE(binary.readFloatLE(offset), i * 8);
  restPlane.writeFloatLE(y, i * 8 + 4);
  restPlane.writeUInt32LE(0xffffff00, depthBytes + i * 4);
  restPlane[depthBytes + i * 4] = Math.round(Math.min(Math.max(z * 2 + 0.5, 0), 1) * 255);
  minY = Math.min(minY, y); maxY = Math.max(maxY, y);
}
const counts = { vertices: positions.count, minY, maxY };

const appendOffset = Math.ceil(binary.length / 4) * 4;
for (const [attribute, offset, length, componentType, type, normalized] of [
  ['TEXCOORD_1', 0, depthBytes, 5126, 'VEC2', false],
  ['COLOR_0', depthBytes, restPlane.length - depthBytes, 5121, 'VEC4', true],
]) {
  const bufferView = gltf.bufferViews.length;
  gltf.bufferViews.push({buffer:0, byteOffset:appendOffset + offset, byteLength:length, target:34962});
  primitive.attributes[attribute] = gltf.accessors.length;
  gltf.accessors.push({bufferView, componentType, count:positions.count, type, normalized});
}
gltf.materials[0].doubleSided = false;
gltf.buffers[0].byteLength = appendOffset + restPlane.length;
const json = Buffer.from(JSON.stringify(gltf));
const paddedJson = Buffer.alloc(Math.ceil(json.length/4)*4, 0x20);
json.copy(paddedJson);
const paddedBinary = Buffer.alloc(appendOffset + restPlane.length);
binary.copy(paddedBinary); restPlane.copy(paddedBinary, appendOffset);
const output = Buffer.alloc(12 + 8 + paddedJson.length + 8 + paddedBinary.length);
output.writeUInt32LE(0x46546c67,0); output.writeUInt32LE(2,4); output.writeUInt32LE(output.length,8);
output.writeUInt32LE(paddedJson.length,12); output.writeUInt32LE(0x4e4f534a,16); paddedJson.copy(output,20);
const binaryHeader = 20+paddedJson.length;
output.writeUInt32LE(paddedBinary.length,binaryHeader); output.writeUInt32LE(0x004e4942,binaryHeader+4);
paddedBinary.copy(output,binaryHeader+8);
fs.writeFileSync(path.join(root,'game/assets/characters/footballer.glb'),output);
console.log(JSON.stringify({vertices:positions.count, restPlane:counts, outputBytes:output.length}));
