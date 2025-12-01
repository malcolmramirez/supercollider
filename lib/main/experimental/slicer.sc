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
    var buf;

    *initClass {
        StartUp.add {
            SynthDef(\Slice_playbuf, {
                var bufnum = \bufnum.kr;
                var numSlices = \numSlices.kr(16);

                var beatsPerSecond = \beatsPerSecond.kr(120/60/60); // bps
                var secondsPerBar = \beatsPerBar.kr(4) / beatsPerSecond;

                var secondsPerFrame = BufFrames.kr(bufnum) / BufSampleRate.kr(bufnum);
                var framesPerSlice = BufFrames.kr(bufnum) / numSlices;

                var sig = PlayBuf.ar(
                    numChannels: 2,
                    bufnum: bufnum,
                    rate: secondsPerFrame / secondsPerBar,
                    doneAction: 0,
                    startPos: framesPerSlice * \slice.kr(0)
                );

                sig = sig * \amp.kr(1);
                sig = sig * Env.perc(
                    0,
                    secondsPerBar / numSlices,
                    curve: \curve.kr(100)
                ).ar(Done.freeSelf);

                Out.ar(\out.kr(0), sig);
            }).add;
        }
    }

    *new { |buf|
        ^super.newCopyArgs(buf);
    }

    playLoop { |times=inf,
            pat=((0..15)),
            n=16,
            speed=1,
            amp=1,
            out=0,
            curve=100,
            clock=(TempoClock.default),
            tdef=nil|
        times.do {
            pat.do { |i|
                this.play(i, n, speed, amp, out, curve, clock)
            }
        }
    }

    play { |i,
            n=16,
            speed=1,
            amp=1,
            out=0,
            curve=100,
            clock=(TempoClock.default)|
        // assuming 4/4 for now
        var waitTime = clock.beatsPerBar / (n * speed);
        var server = Server.default;
        server.bind {
            Synth(\Slice_playbuf, [
                \bufnum, buf,
                \numSlices, n,
                \amp, amp,
                \out, out,
                \beatsPerSecond, clock.tempo * speed,
                \beatsPerBar, clock.beatsPerBar,
                \slice, i,
                \curve, curve
            ]);
        };
        waitTime.wait;
    }
}
