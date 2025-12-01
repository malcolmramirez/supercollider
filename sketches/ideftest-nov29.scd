(
TempoClock.default.tempo = (150/60);

Ndef(\kd, {
    var sig, env, pitchEnv, imp;

    imp = \trig.kr;
    env = Env.perc(0.01, 0.075).ar(gate: imp);
    pitchEnv = Env([1, 2, 1], [0.01], curve: -4).ar(gate: imp);
    
    sig = SinOsc.ar(55 * pitchEnv);
    sig = sig * env * 5.dbamp;

    sig!2;
})
.map(
    \trig, 
    Mpulse.ndef(\p1, "1 ~", 2))
.play;

Ndef(\hh, {
    var sig;

    sig = WhiteNoise.ar(0.025) ! 3;
    sig = sig * Env.perc(0.01, 0.025).ar(gate: \trig.kr);

    Splay.ar(sig);
})
.map(
    \trig, 
    Mpulse.ndef(\p2, "~ ~ 1 ~", 4))
.play;

Ndef(\snare, {
    var sig, env, pitchEnv, imp;

    imp = \trig.kr;    
    env = Env.perc(0.01, 0.1).ar(gate: imp);
    pitchEnv = Env([1, 2, 1], [0.01], curve: -1).ar(gate: imp);
    
    sig = Mix.ar(
        [SinOsc.ar(330 * pitchEnv)],
        Hasher.ar(
            [Saw.ar(220), Pulse.ar(334), SinOsc.ar(110)]) 
                * 0.5 
                * Env.perc(0.05, 0.02).ar(gate: imp));
    sig = sig * env * 12.5.dbamp;
    sig = RLPF.ar(sig, 220, pitchEnv.linlin(1, 2, 0.05, 1));
    sig = Resonz.ar(sig, 440, 8 * SinOsc.ar(0.5).linlin(-1, 1, 1, 2));

    sig!2;
})
.map(
    \trig,
    Mpulse.ndef(\p3, "~ 1 ~ 1"))
.play;

)

UnitTest.runAll;
