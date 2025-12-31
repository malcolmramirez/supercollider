
p.clear;
(
b = 120/60;
p = ProxySpace(s)
    .fadeTime_(0)
    .quant_(4)
    .makeTempoClock(b)
    .push;
)

~out.play;

~out[0] = {
    var sig;

    sig = SoundIn.ar([0, 1]);
}
