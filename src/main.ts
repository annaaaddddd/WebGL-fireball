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
import noiseSource from './shaders/noise.glsl?raw';
import colorSource from './shaders/color.glsl?raw';
import backgroundVertSource from './shaders/background-vert.glsl?raw';
import backgroundFragSource from './shaders/background-frag.glsl?raw';


// GLSL has no native #include; our shaders are imported as plain strings, so
// we splice shared helper files in ourselves before compiling. Only known
// includes are replaced where an unknown one is left in place so the GLSL
// compiler fails loudly instead of silently.
const shaderIncludes: [string, string][] = [
  ['#include "noise.glsl"', noiseSource],
  ['#include "color.glsl"', colorSource],
];

function assembleShader(source: string): string {
  for (const [directive, code] of shaderIncludes) {
    source = source.replace(directive, code);
  }
  return source;
}

// The art-directed default look; the reset button restores these.
const defaults = {
  tesselations: 6,
  theme: 0,
  wobble: 0.1,
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
  renderer.setClearColor(0, 0, 0, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, assembleShader(lambertVertSource)),
    new Shader(gl.FRAGMENT_SHADER, assembleShader(lambertFragSource)),
  ]);

  const background = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, assembleShader(backgroundVertSource)),
    new Shader(gl.FRAGMENT_SHADER, assembleShader(backgroundFragSource)),
  ]);

  // This function will be called every frame
  function tick(timeMs: number) {
    const time = timeMs / 1000.0;
    lambert.setTime(time);
    background.setTime(time);
    background.setAspect(window.innerWidth / window.innerHeight);
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
    gl.depthMask(false);
    renderer.render(camera, background, [
      square,
    ]);
    gl.depthMask(true);
    renderer.render(camera, lambert, [
      icosphere,
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
