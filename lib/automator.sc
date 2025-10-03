Automator {

    var synth;

    *new { |synth|
        // func should be constrained to 0,1 on the x and y axes.
        ^super.newCopyArgs(synth);
    }

    run { |dur, spec, clock = (TempoClock.default), s = (Server.default)|

        var numSteps = ceil(30 * clock.beatDur * dur); // 30 steps per second
        var waitTime = dur / numSteps;
        var outputs = Dictionary();
        var ymins = Dictionary();
        var ymaxes = Dictionary();
        var parsedSpec = Dictionary();

        spec.do { |subspec|
            var parsedSubSpec = Dictionary();
            subspec.pairsDo { |key, value|
                parsedSubSpec[key] = value;
            };
            parsedSpec[parsedSubSpec[\param]] = parsedSubSpec;
            parsedSubSpec.put(\param, nil);
        };

        numSteps.do { |step|
            parsedSpec.pairsDo { |key, value|
                var xrange = value[\over] ?? [0, 1];
                var normalizedStep = step.linlin(0, numSteps - 1, xrange[0], xrange[1]);
                var y = (value[\func] ?? ({|x| x})).(normalizedStep);
                var outputList = outputs[key] ?? List();

                outputs[key] = outputList.add(y);
                ymins[key] = min(ymins[key] ?? inf, y);
                ymaxes[key] = max(ymaxes[key] ?? (-1*inf), y);
            };
        };

        fork {
            numSteps.do { |step|
                var stepArgs = Dictionary();
                parsedSpec.pairsDo { |key, value|
                    stepArgs[key] = outputs[key][step].linlin(
                        ymins[key], ymaxes[key], value[\range][0], value[\range][1]);
                };
                s.bind {
                    s.listSendMsg(["/n_set", synth.nodeID] ++ stepArgs.asPairs.flatten);
                };
                waitTime.wait;
            }
        }
    }
}