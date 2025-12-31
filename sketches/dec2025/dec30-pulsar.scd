(
b = 120/60;
p = ProxySpace(s)
    .fadeTime_(0)
    .quant_(4)
    .makeTempoClock(b)
    .push;
)

~p1.play;

( 
~p1[0] = Pbind(
    \instrument, \pulsar,
    \dur, 1,
    \ffreq, Pexprand(100, 200),
    \buf, d[\sigs][0],
    \decree, [0, 2, 5],
    \octave, 3,
    \window, 0,
    \sust, Pkey(\dur) * 0.9,
    \atk, Pkey(\dur) * 0.05,
    \rel, Pkey(\dur) * 0.05,
    \amp, 1
);
~p1[1] = \filterIn -> { |in|
    RLPF.ar(in, 440, Saw.ar(b).range(0.1, 1))
};
)
