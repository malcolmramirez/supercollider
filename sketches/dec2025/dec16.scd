(

p = ProxySpace(s);

)

(
SynthDef(\simpleSaw, {
    var sig, env;

    env = Env.perc(\atk.kr(0.1), \rel.kr(0.5)).kr(Done.freeSelf);

    sig = Saw.ar(\freq.kr);

    sig = sig * env;

    Out.ar(\i_out.kr(0), sig!2);
}).add;

p[\in] = Pbind(
    \instrument, \simpleSaw,
    \dur, Pdefn(\dur, 0.5),
    \freq, Pdefn(\freq, Pseq(["c3", "d5", "a3", "c3"].collect{ |f| Note.toFreq(f) }, inf))
);

p[\lpf] = {
    SinOsc.ar(0.1).linlin(-1, 1, 200, 1500);
};
p[\lpq] = 1;
p[\lowPass] = {
    RLPF.ar(p[\in].ar, p[\lpf], p[\lpq]);
};
p[\out] = {
    p[\lowPass].ar
};

)

// Hotswap the freq pdef
Pdefn(\freq, Pseq(["c3", "d4", "a3", "c3"].collect{ |f| Note.toFreq(f) }, inf))

// Hotswap the dur pdef
Pdefn(\dur, 1/8)

(
// pattern on lpf
Pdefn(\lpfDriver,
    Pbind(
        \type, \rest,
        \dur, 1/2,
        \value, Pseq([500, 200, 400, 200], inf)
    ).collect { |event|
        p[\lpf] = event[\value];
        event;
    }
).stop;

)

// Replace lpf with an lfo
p[\lpf] = {
    SinOsc.ar(0.1).linlin(-1, 1, 200, 1500);
}


p[\out].play;