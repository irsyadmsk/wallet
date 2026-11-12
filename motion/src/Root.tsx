import React from 'react';
import { AbsoluteFill, Composition, Sequence } from 'remotion';
import { fps } from './theme';
import { Fonts } from './ui';
import { Welcome } from './Welcome';
import { INTRO, Intro, OUTRO, Outro, SCENE, SceneCalendar, SceneLinks, ScenePlan,
  SceneWallets } from './scenes';

const scenes = [ScenePlan, SceneWallets, SceneCalendar, SceneLinks];

const Film: React.FC<{ intro: string; outro: string }> = ({ intro, outro }) => (
  <AbsoluteFill>
    <Fonts />
    <Sequence durationInFrames={INTRO}><Intro line={intro} /></Sequence>
    {scenes.map((S, i) => (
      <Sequence key={i} from={INTRO + i * SCENE} durationInFrames={SCENE}><S /></Sequence>
    ))}
    <Sequence from={INTRO + scenes.length * SCENE}><Outro line={outro} /></Sequence>
  </AbsoluteFill>
);

const filmLength = INTRO + scenes.length * SCENE + OUTRO;

export const Root: React.FC = () => (
  <>
    {/* Seamless 10 s loop behind the welcome screen. */}
    <Composition id="Welcome" component={Welcome} fps={fps} width={1920} height={1080}
      durationInFrames={300} />
    {/* Portrait feature tour for phones and social posts. */}
    <Composition id="Tur" component={Film} fps={fps} width={1080} height={1920}
      durationInFrames={filmLength}
      defaultProps={{ intro: 'Empat hal baru dalam buku kas Anda',
        outro: 'Catat, rencanakan, lalu tenang.' }} />
    {/* Landscape promo for the store listing. */}
    <Composition id="PlayStore" component={Film} fps={fps} width={1920} height={1080}
      durationInFrames={filmLength}
      defaultProps={{ intro: 'Buku kas pribadi dan keluarga',
        outro: 'Keuangan yang rapi, tanpa repot.' }} />
  </>
);
