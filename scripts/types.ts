export enum Layer {
  L2 = 'l2',
  L3 = 'l3'
}

export interface Package {
  name: string;
  base_path: string;
}

export interface Contract {
  name: string;
  layer: Layer;
  package: Package;
  classHash?: string;
  address?: string;
}