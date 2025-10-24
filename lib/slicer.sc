Slicer {

    var args, transitionFunction, currentSlice, waitTime, playing, sems, s;

    *new {|buffer, rateMultiplier=1, startSlice=0, transitionFunction=nil, out=0,
        amp=1, numSlices=16, clock=(TempoClock.default), s=(Server.default)|

        var sampleDur = buffer.numFrames / buffer.sampleRate;
        var playbackRate = sampleDur / (clock.beatsPerBar / clock.tempo) * rateMultiplier;
        var waitTime = (clock.beatsPerBar * (1 / numSlices)) * rateMultiplier.reciprocal;
        var args = [
                \out, out,
                \amp, amp,
                \buffer, buffer,
                \bufferFrames, buffer.numFrames,
                \numSlices, numSlices,
                \rateMultiplier, rateMultiplier,
                \playbackRate, sampleDur / (clock.beatsPerBar / clock.tempo) * rateMultiplier,
                \playDur, waitTime * clock.beatDur,
            ];

        if (transitionFunction == nil) {
            transitionFunction = {|i| (i + 1) % numSlices};
        };

        SynthDef(\Slicer_playbuf, {
            var start = \bufferFrames.kr * (\slice.kr / \numSlices.kr);
            var sig = PlayBuf.ar(numChannels: 2, startPos: start, bufnum: \buffer.kr, rate: \playbackRate.kr);
            sig = sig * \amp.kr(1);
            sig = sig * Env.perc(0, \playDur.kr, curve: 100).kr(Done.freeSelf);

            Out.ar(\out.kr(0), sig ! 2);
        }).add;
        s.sync;

        ^super.newCopyArgs(
            args,
            transitionFunction,
            startSlice,
            waitTime,
            true,
            (slice: Semaphore(), play: Semaphore()),
            s);
    }

    play {
        sems[\play].wait;
        playing = true;
        sems[\play].signal;

        fork {
            while { playing } {
                s.bind {
                    Synth(\Slicer_playbuf, args ++ [\slice, currentSlice]);
                };
                sems[\slice].wait;
                currentSlice = transitionFunction.(currentSlice);
                sems[\slice].signal;
                waitTime.wait;
            }
        }
    }

    pause {
        sems[\play].wait;
        playing = false;
        sems[\play].signal;
    }

    reset {
        sems[\slice].wait;
        currentSlice = 0;
        sems[\slice].signal;
    }

    stop {
        this.pause;
        this.reset;
    }
}

Slice {
    var n;
    var buf;
    var args;
    var waitTime;
    var s;

    *initClass {
        StartUp.add {
            SynthDef(\Slice_playbuf, {
                var sig = PlayBuf.ar(
                    numChannels: 2,
                    bufnum: \buf.kr,
                    rate: \rate.kr,
                    doneAction: 0,
                    startPos: \numFrames.kr * (\slice.kr / \n.kr)
                );
                sig = sig * \amp.kr(1);
                sig = sig * Env.perc(0, \dur.kr, curve: -4).kr(Done.freeSelf);
                Out.ar(\out.kr(0), sig);
            }).add;
        }
    }

    *new { |n, buf, speed=1, args=([]), clock=(TempoClock.default), s=(Server.default)|
        var sampleDur = buf.numFrames / buf.sampleRate;
        var rate = sampleDur / (clock.beatsPerBar / clock.tempo) * speed;
        var waitTime = (clock.beatsPerBar * (1 / n)) * speed.reciprocal;
        args = args ++ [
            \buf, buf,
            \numFrames, buf.numFrames,
            \n, n,
            \rate, rate,
            \dur, waitTime * clock.beatDur,
        ];

        ^super.newCopyArgs(n, buf, args, waitTime, s);
    }

    loop { |times=inf|
        times.do {
            n.do { |i|
                this.play(i)
            }
        }
    }

    play { |i|
        s.bind {
            Synth(\Slice_playbuf, args ++ [\slice, i]);
        };
        waitTime.wait;
    }
}