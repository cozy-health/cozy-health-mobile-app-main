const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
// Raster export of the original vector artwork. No recolouring or retouching.
(async () => {
  for (const name of ['anxiety', 'burnout', 'wellbeing', 'gratitude']) {
    const original = path.join(__dirname, '..', 'assets', 'svg', `recommended_${name}.svg`);
    const png = path.join(__dirname, '..', 'assets', 'png', `recommended_${name}.png`);
    const art = await sharp(fs.readFileSync(original), {density: 600}).trim().toBuffer();
    await sharp(art).resize(320, 320, {fit:'inside'}).extend({top:32,bottom:32,left:32,right:32,background:{r:0,g:0,b:0,alpha:0}}).png().toFile(png);
    process.stdout.write(`${name}: exported original artwork\n`);
  }
})();
