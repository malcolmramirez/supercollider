Automator {

    var synth;

    *new { |synth|
        // func should be constrained to 0,1 on the x and y axes.
        ^super.newCopyArgs(synth);
    }

    run {
        arg dur,
            spec,
            clock = TempoClock.default,
            s = Server.default;

        var numSteps = ceil(30 * clock.beatDur * dur), // 30 steps per second
            waitTime = dur / numSteps,
            outputs = Dictionary(),
            ymins = Dictionary(),
            ymaxes = Dictionary();

        numSteps.do { |step|
            spec.pairsDo { |key, value|
                var xrange = value[\xrange] ?? [0, 1],
                    normalizedStep = step.linlin(0, numSteps - 1, xrange[0], xrange[1]),
                    y = (value[\func] ?? ({|x| x})).(normalizedStep),
                    outputList = outputs[key] ?? List();

                outputs[key] = outputList.add(y);
                ymins[key] = min(ymins[key] ?? inf, y);
                ymaxes[key] = max(ymaxes[key] ?? (-1*inf), y);
            };
        };

        fork {
            numSteps.do { |step|
                var stepArgs = Dictionary();
                spec.pairsDo { |key, value|
                    stepArgs[key] = outputs[key][step].linlin(
                        ymins[key], ymaxes[key], value[\from], value[\to]);
                };
                s.bind {
                    s.listSendMsg(["/n_set", synth.nodeID] ++ stepArgs.asPairs.flatten);
                };
                waitTime.wait;
            }
        }
    }
}