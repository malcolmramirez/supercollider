CycleSynth {
    var server;
    var <>synthDefName;
    var <>synthDef;
    var <>synthDefArgs;

    *new { |synthDef|
        ^super.newCopyArgs(Server.default, nil, nil, Dictionary[]);
    }

    ingestEvent { |event|
        var oldSynthDefArgs = synthDefArgs;
        synthDefArgs.putAll(event.synthDefArgs);

        if (notNil(event.synthDef)) {
            this.synthDefName = event.synthDef;
        };

        if (notNil(event.spawn) && notNil(synthDefName)) {
            server.bind {
                this.synthDef = Synth.new(synthDefName, synthDefArgs.asPairs, server);
                NodeWatcher.register(synthDef);
            }
            ^this;
        };

        if (notNil(synthDef){_.isRunning} && (oldSynthDefArgs != synthDefArgs)) {
            server.bind {
                var msg = ["/n_set", synthDef.nodeID] ++ synthDefArgs.asPairs;
                server.listSendMsg(msg);
            };
        };
    }
}

TimelineEvent {
    var <>speed;
    var <>spawn;
    var <>synthDef;
    var <>synthDefArgs;

    *new { |speed, spawn, synthDef, synthArgs|
        ^super.newCopyArgs(nil, nil, nil, Dictionary[]);
    }

    put { |paramName, paramBinding|
        var empty = { |b| (b == \) || isNil(b) };

        if (empty.(paramBinding)) {
            ^this;
        };

        if (paramName == \speed) {
            this.speed = paramBinding;
            ^this;
        };

        if ((paramName == \spawn) && (paramBinding != 0)) {
            this.spawn = paramBinding;
            ^this;
        };

        if (paramName == \def) {
            this.synthDef = paramBinding;
            ^this;
        };

        synthDefArgs[paramName] = paramBinding;
        ^this;
    }

    postln {
        ("TimelineEvent\n" ++
            "\tspeed=" ++ this.speed ++ "\n" ++
            "\tspawn=" ++ this.spawn ++ "\n" ++
            "\tsynthDef=" ++ this.synthDef ++ "\n" ++
            "\tsynthDefArgs=" ++ this.synthDefArgs).postln;
    }
}

Cycle {
    var cycleSynth; // all available parameters
    var params;
    var clock;

    *new {
        ^super.newCopyArgs(
            CycleSynth(),
            Dictionary[],
            TempoClock(TempoClock.default.tempo));
    }

    add { |paramBinding|
        params[paramBinding.key] = paramBinding.value;
    }

    flattenBinding { |binding, stepSize, offset|
        var result = [];

        var bindingValue = binding.value;

        if (bindingValue.isKindOf(SequenceableCollection)) {
            var subStepSize = stepSize / bindingValue.size;
            bindingValue.do { |binding, i|
                var subOffset = offset + (i * subStepSize);
                result = result ++ this.flattenBinding(binding, subStepSize, subOffset);
            };
        } {
            result = result.add((time: offset, binding: bindingValue));
        };

        ^result;
    }

    buildTimeline {
        var timeline = Dictionary[];

        params.pairsDo { |param, binding|
            var events = this.flattenBinding(binding, 1, 0);
            events.do { |event|
                var time = event.time;
                var timelineEvent = timeline.atFail(time, TimelineEvent());
                timelineEvent[param] = event.binding;
                timeline[time] = timelineEvent;
            };
        };

        ^timeline;
    }

    run {
        var length = 4;
        var originalTempo = clock.tempo;

        clock.sched(0, {
            var timeline = this.buildTimeline();

            timeline.pairsDo { |relativeTime, event|
                var time = relativeTime * length;

                clock.sched(time, {
                    if (notNil(event.speed)) {
                        clock.tempo = originalTempo * event.speed;
                    };
                    cycleSynth.ingestEvent(event);
                });
            };

            length;
        });
    }

    stop {
        clock.clear;
    }
}

Alt {
    var items;
    var ptr;

    *new { |...items|
        ^super.newCopyArgs(items, 0);
    }

    value {
        var tmp = items[ptr];
        ptr = (ptr + 1) % items.size;
        ^tmp.value;
    }
}

Euc {
    var k;
    var n;
    var o;
    var on;
    var off;

    *new { |k, n, o=0, on=1, off=nil|
        ^super.newCopyArgs(k, n, o, on, off);
    }

    value {
        var items = (
            (k / n * (0..n - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (k <= 0) { 0 } { 1 }
        );
        items = items.rotate(o.value);
        items = items.collect({ |i|
            if (i == 0) { off.value } { on.value }
        });
        ^items;
    }
}