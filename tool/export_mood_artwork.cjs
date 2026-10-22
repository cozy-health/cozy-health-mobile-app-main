const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');

// Export the original vector paths, gradients and filters. No raster retouching.
const sourcePath = process.argv[2];
if (!sourcePath) throw new Error('Pass the original Frame 1000004108 (1).svg path.');
const root = path.resolve(__dirname, '..');
const original = fs.readFileSync(sourcePath, 'utf8');
const source = original
  .replace(/<rect\b[^>]*height="45"[^>]*\/>/g, '')
  .replace(/<path\b[^>]*fill="#414651"[^>]*\/>/g, '');
// Body bounds exclude shadows. Equal body area preserves the tall/wide shapes
// while giving them equal visual weight. Every full filter fits within its crop.
const entries = [
  {mood: 'angry', body: [16, 10.5, 24, 24], filter: [10, 4.5, 36, 36]},
  {mood: 'sad', body: [129, 10.5, 30.2069, 24], filter: [124.034, 5.53448, 40.1379, 33.931]},
  {mood: 'good', body: [242.993, 11.4163, 22.1671, 22.1671], filter: [239.022, 7.44603, 30.1076, 30.1077]},
  {mood: 'upset', body: [355, 7, 24.6301, 31], filter: [349.904, 1.90411, 34.8219, 41.1918]},
  {mood: 'spectacular', body: [468, 9.61475, 24, 25.77045], filter: [463.279, 4.89343, 33.4426, 35.2131]},
  {mood: 'happy', body: [608.29459, 12.5686, 26.41092, 19.863], filter: [604.185, 8.45901, 34.6301, 28.0822]},
];
(async () => {
  for (const entry of entries) {
    const [x,y,w,h] = entry.body;
    const side = Math.sqrt(w*h) * 48/28;
    const crop = [x+w/2-side/2, y+h/2-side/2, side, side];
    const [fx,fy,fw,fh] = entry.filter;
    if (fx < crop[0] || fy < crop[1] || fx+fw > crop[0]+side || fy+fh > crop[1]+side) {
      throw new Error(entry.mood + ' would crop its original shadow');
    }
    const svg = source.replace(/<svg\b[^>]*>/,
      '<svg width="384" height="384" viewBox="' + crop.join(' ') + '" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    const png = await sharp(Buffer.from(svg)).png().toBuffer();
    const filename = 'assets/png/home_reference_' + entry.mood + '.png';
    fs.writeFileSync(path.join(root,filename),png);
    const {data,info} = await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    let edgeAlpha = 0;
    for(let i=0;i<info.width;i++) {
      edgeAlpha = Math.max(edgeAlpha,data[(i*4)+3],data[((info.height-1)*info.width+i)*4+3],data[(i*info.width)*4+3],data[(i*info.width+info.width-1)*4+3]);
    }
    if (edgeAlpha > 1) throw new Error(entry.mood + ' touches an export edge');
    Object.assign(entry,{crop,filename,sha256:crypto.createHash('sha256').update(png).digest('hex'),edgeAlpha});
  }
  const manifest = {source:path.basename(sourcePath),sourceSha256:crypto.createHash('sha256').update(original).digest('hex'),pixelSize:384,bodyAreaFraction:(28/48)**2,entries};
  fs.mkdirSync(path.join(root,'docs/design'),{recursive:true});
  fs.writeFileSync(path.join(root,'docs/design/mood-artwork-export.json'),JSON.stringify(manifest,null,2)+'\n');
  console.log('Exported six original vector characters with balanced body area and complete shadow bounds.');
})();
