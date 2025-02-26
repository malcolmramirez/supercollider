SynthDef.new("tutorial-SinOsc", { |out| Out.ar(out, SinOsc.ar(220, 0, 0.2)) }).add;
x = Synth.new("tutorial-SinOsc", ["out", [0, 1]]);
x.free;