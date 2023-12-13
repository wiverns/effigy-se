export type AvailableJob = keyof typeof JOB2ICON;

/** Icon map of jobs to their fontawesome5 (free) counterpart. */
export const JOB2ICON = {
  AI: 'eye',
  Assistant: 'toolbox',
  'Atmospheric Technician': 'fan',
  Bartender: 'cocktail',
  'Bit Avatar': 'code',
  Bitrunner: 'gamepad',
  Botanist: 'seedling',
  'Broadcast Team': 'video-camera', // EffigyEdit Add (Broadcast Team)
  Captain: 'crown',
  'Cargo Technician': 'box',
  'CentCom Commander': 'star',
  'CentCom Head Intern': 'pen-fancy',
  'CentCom Intern': 'pen-alt',
  'CentCom Official': 'medal',
  Chaplain: 'cross',
  Chef: 'utensils',
  Chemist: 'prescription-bottle',
  'Chief Engineer': 'user-astronaut',
  'Chief Medical Officer': 'user-md',
  Clown: 'face-grin-tears',
  Cook: 'utensils',
  Coroner: 'skull',
  Curator: 'book',
  'Cyber Police': 'qrcode',
  Cyborg: 'robot',
  Detective: 'user-secret',
  Geneticist: 'dna',
  'Head of Personnel': 'dog',
  'Head of Security': 'user-shield',
  Janitor: 'soap',
  Lawyer: 'gavel',
  'Medical Doctor': 'staff-snake',
  Mime: 'comment-slash',
  Paramedic: 'truck-medical',
  'Personal AI': 'mobile-alt',
  Prisoner: 'lock',
  Psychologist: 'brain',
  Quartermaster: 'sack-dollar',
  'Research Director': 'user-graduate',
  Roboticist: 'battery-half',
  Scientist: 'flask',
  'Security Officer (Cargo)': 'shield-halved',
  'Security Officer (Engineering)': 'shield-halved',
  'Security Officer (Medical)': 'shield-halved',
  'Security Officer (Science)': 'shield-halved',
  'Security Officer': 'shield-halved',
  'Shaft Miner': 'digging',
  'Station Engineer': 'gears',
  'Syndicate Operative': 'dragon',
  Virologist: 'virus',
  Warden: 'handcuffs',
} as const;
