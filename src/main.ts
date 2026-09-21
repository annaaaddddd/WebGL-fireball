import {vec3} from 'gl-matrix';
import Stats from 'stats-js';
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

import lambertVertSource from './shaders/lambert-vert.glsl?raw';
import lambertFragSource from './shaders/lambert-frag.glsl?raw';

// The art-directed default look; the reset button restores these.
const defaults = {
  tesselations: 6,
  theme: 0,
  wobble: 0.3,
  noiseAmount: 0.15,
  noiseScale: 5.0,
  heat: 0.35,
  speed: 0.3,
};

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  ...defaults,
  'Reset to Default': () => { Object.assign(controls, defaults); },
};

let icosphere: Icosphere;
let square: Square;
let prevTesselations: number = defaults.tesselations;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui. Every control is .listen()-ed so the reset
  // button's Object.assign is reflected in the UI automatically.
  const gui = new DAT.GUI();

  const shapeFolder = gui.addFolder('Shape');
  shapeFolder.add(controls, 'wobble', 0, 0.6).name('Wobble').listen();
  shapeFolder.add(controls, 'noiseAmount', 0, 0.5).name('Noise Amount').listen();
  shapeFolder.add(controls, 'noiseScale', 1, 12).name('Noise Scale').listen();
  shapeFolder.open();

  const appearanceFolder = gui.addFolder('Appearance');
  appearanceFolder.add(controls, 'theme', { Fire: 0, Ghostfire: 1, Toxic: 2, Cosmic: 3 })
      .name('Theme').listen();
  appearanceFolder.add(controls, 'heat', 0.15, 0.65).name('Heat').listen();
  appearanceFolder.open();

  const motionFolder = gui.addFolder('Motion');
  motionFolder.add(controls, 'speed', 0, 1).name('Speed').listen();

  gui.add(controls, 'tesselations', 0, 8).step(1).name('Mesh Detail').listen();
  gui.add(controls, 'Reset to Default').name('Click to Reset');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, lambertVertSource),
    new Shader(gl.FRAGMENT_SHADER, lambertFragSource),
  ]);

  // This function will be called every frame
  function tick(timeMs: number) {
    const time = timeMs / 1000.0;
    lambert.setTime(time);
    // dat.GUI dropdowns store their value as a string once the user picks an
    // option, so coerce back to a number before uploading the uniform.
    lambert.setTheme(Number(controls.theme));
    lambert.setSpeed(controls.speed);
    lambert.setWobble(controls.wobble);
    lambert.setFbmAmp(controls.noiseAmount);
    lambert.setFbmFreq(controls.noiseScale);
    lambert.setHeat(controls.heat);
    camera.update();
    stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();
    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    renderer.render(camera, lambert, [
      icosphere,
      // square,
    ]);
    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  requestAnimationFrame(tick);
}

main();
