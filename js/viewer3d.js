// Responsibility: CS2 wear shader viewer (Three.js ES module)
import * as THREE from 'three';
import { GLTFLoader }    from 'three/addons/loaders/GLTFLoader.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const VERT = `
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewDir;
void main() {
  vUv = uv;
  vNormal = normalize(normalMatrix * normal);
  vec4 wp = modelMatrix * vec4(position, 1.0);
  vViewDir = normalize(cameraPosition - wp.xyz);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}`;

const FRAG = `
precision highp float;
uniform sampler2D u_albedo;
uniform sampler2D u_wearMask;
uniform float u_float;
uniform float u_seed;
uniform float u_finishStyle;
uniform bool  u_hasAlbedo;
uniform bool  u_hasWearMask;
varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vViewDir;

vec2 patternUV(vec2 uv, float seed) {
  float h  = fract(sin(seed * 127.1 + 311.7) * 43758.5453);
  float a  = h * 6.28318;
  float ox = fract(h * 31.71);
  float oy = fract(h * 17.31);
  vec2  c  = uv - 0.5;
  float co = cos(a), si = sin(a);
  c = vec2(co*c.x - si*c.y, si*c.x + co*c.y);
  return c + 0.5 + vec2(ox, oy);
}

vec3 substrateMetal(vec2 uv) {
  float n = fract(sin(uv.x * 1453.0 + uv.y * 2177.0) * 9301.0);
  float v = 0.30 + n * 0.12;
  return vec3(v + 0.012, v + 0.016, v + 0.022);
}

void main() {
  vec2 pUv = patternUV(vUv, u_seed);

  vec4 albedoSample = u_hasAlbedo
    ? texture2D(u_albedo, pUv)
    : vec4(0.50, 0.47, 0.44, 1.0);

  float wearMask = u_hasWearMask
    ? texture2D(u_wearMask, vUv).r
    : albedoSample.a;

  float thresh = u_finishStyle > 1.5 ? u_float * 0.6 : u_float;
  bool  worn   = wearMask < thresh;

  vec3 substrate = substrateMetal(vUv);
  vec3 skin      = albedoSample.rgb;
  vec3 color;

  if (u_finishStyle < 0.5) {
    color = worn ? substrate : skin;
  } else if (u_finishStyle < 1.5) {
    vec3 aged = skin * (1.0 - u_float * 0.42);
    color = mix(aged, substrate * 0.65, u_float * 0.28);
  } else {
    color = worn ? mix(skin, substrate, 0.88) : skin;
  }

  float ndotl = max(dot(vNormal, normalize(vec3(1.0, 1.5, 1.0))), 0.0);
  color *= 0.42 + 0.68 * ndotl;
  float fresnel = pow(1.0 - clamp(dot(vNormal, vViewDir), 0.0, 1.0), 3.0);
  color += 0.035 * fresnel;

  gl_FragColor = vec4(color, 1.0);
}`;

const _defaultTex = (() => {
  const t = new THREE.DataTexture(new Uint8Array([180,176,172,255]), 1, 1, THREE.RGBAFormat);
  t.needsUpdate = true;
  return t;
})();

class CS2SkinViewer {
  constructor(canvas, w, h) {
    this.canvas    = canvas;
    this._hasModel = false;
    this._raf      = null;
    this._loader   = new GLTFLoader();
    this._texLoad  = new THREE.TextureLoader();

    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
    this.renderer.setSize(w, h);
    this.renderer.outputColorSpace = THREE.SRGBColorSpace;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x111418);

    this.camera = new THREE.PerspectiveCamera(45, w / h, 0.01, 100);
    this.camera.position.set(0, 0, 2.5);

    this.controls = new OrbitControls(this.camera, canvas);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.08;

    const amb  = new THREE.AmbientLight(0xffffff, 0.5);
    const dir  = new THREE.DirectionalLight(0xffffff, 1.2);
    dir.position.set(2, 3, 2);
    const fill = new THREE.DirectionalLight(0x8899cc, 0.3);
    fill.position.set(-2, -1, -2);
    this.scene.add(amb, dir, fill);

    this.mat = new THREE.ShaderMaterial({
      vertexShader:   VERT,
      fragmentShader: FRAG,
      uniforms: {
        u_albedo:      { value: _defaultTex },
        u_wearMask:    { value: _defaultTex },
        u_float:       { value: 0.15  },
        u_seed:        { value: 1.0   },
        u_finishStyle: { value: 0.0   },
        u_hasAlbedo:   { value: false },
        u_hasWearMask: { value: false },
      },
    });

    const geo = new THREE.BoxGeometry(1.8, 0.18, 0.09);
    this._placeholder = new THREE.Mesh(geo, this.mat);
    this._placeholder.rotation.x = 0.25;
    this.scene.add(this._placeholder);

    this._animate();
  }

  _animate() {
    this._raf = requestAnimationFrame(() => this._animate());
    this.controls.update();
    if (!this._hasModel) this._placeholder.rotation.y += 0.006;
    this.renderer.render(this.scene, this.camera);
  }

  loadGLB(arrayBuffer) {
    this._loader.parse(arrayBuffer, '', gltf => {
      this.scene.remove(this._placeholder);
      this._hasModel = true;
      const root = gltf.scene;
      root.traverse(c => { if (c.isMesh) c.material = this.mat; });
      const box    = new THREE.Box3().setFromObject(root);
      const sz     = new THREE.Vector3();
      box.getSize(sz);
      const scale  = 2.0 / Math.max(sz.x, sz.y, sz.z);
      root.scale.setScalar(scale);
      const center = new THREE.Vector3();
      box.getCenter(center);
      root.position.copy(center.multiplyScalar(-scale));
      this.scene.add(root);
      const canvas = document.getElementById('viewer3dCanvas');
      const drop   = document.getElementById('viewerDrop');
      const ctrl   = document.getElementById('viewerControls');
      if (canvas) canvas.style.display = 'block';
      if (drop)   drop.style.display   = 'none';
      if (ctrl)   ctrl.style.display   = 'flex';
    }, err => console.error('[CS2Viewer] GLB error', err));
  }

  setAlbedo(tex) {
    tex.colorSpace = THREE.SRGBColorSpace;
    tex.needsUpdate = true;
    this.mat.uniforms.u_albedo.value    = tex;
    this.mat.uniforms.u_hasAlbedo.value = true;
  }

  setWearMask(tex) {
    tex.needsUpdate = true;
    this.mat.uniforms.u_wearMask.value    = tex;
    this.mat.uniforms.u_hasWearMask.value = true;
  }

  setFloat(v)  { this.mat.uniforms.u_float.value      = parseFloat(v) || 0.0; }
  setSeed(v)   { this.mat.uniforms.u_seed.value        = parseFloat(v) || 1.0; }
  setFinish(v) { this.mat.uniforms.u_finishStyle.value = parseFloat(v) || 0.0; }

  processFiles(files) {
    for (const file of files) {
      const name = file.name.toLowerCase();
      if (name.endsWith('.glb')) {
        const fr = new FileReader();
        fr.onload = e => this.loadGLB(e.target.result);
        fr.readAsArrayBuffer(file);
      } else if (/\.(png|jpg|jpeg|webp)$/.test(name)) {
        const url = URL.createObjectURL(file);
        this._texLoad.load(url, tex => {
          if (/albedo|color|diff|paint/i.test(name)) this.setAlbedo(tex);
          else if (/wear|mask|alpha/i.test(name))    this.setWearMask(tex);
          URL.revokeObjectURL(url);
        });
      }
    }
  }

  resize(w, h) {
    if (!w || !h) return;
    this.renderer.setSize(w, h);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  dispose() {
    if (this._raf) cancelAnimationFrame(this._raf);
    this.controls.dispose();
    this.renderer.dispose();
  }
}

window.CS2SkinViewer = CS2SkinViewer;
