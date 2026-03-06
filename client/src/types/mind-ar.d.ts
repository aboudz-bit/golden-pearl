declare module "mind-ar/dist/mindar-image-three.prod.js" {
  export class MindARThree {
    constructor(options: {
      container: HTMLElement;
      imageTargetSrc: string;
      maxTrack?: number;
      uiLoading?: string;
      uiScanning?: string;
      uiError?: string;
    });
    renderer: any;
    scene: any;
    camera: any;
    addAnchor(targetIndex: number): {
      group: any;
      onTargetFound: (() => void) | null;
      onTargetLost: (() => void) | null;
    };
    start(): Promise<void>;
    stop(): void;
  }
}
