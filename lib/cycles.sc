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
    var cycleSynth;
    var params;
    var clock;

    *new {
        ^super.newCopyArgs(
            CycleSynth(),
            Dictionary[],
            TempoClock(TempoClock.default.tempo));
    }

    add { |paramBinding|
        params[paramBinding.key] = TimeSeq(paramBinding.value);
    }

    run {
        var length = 4;
        var position = 0;
        var originalTempo = clock.tempo;

        clock.sched(0, {
            var findMinTime = {
                var minTime = inf;
                params.pairsDo { |param, timeSeq|
                    var event = timeSeq.peek;
                    if (notNil(event)) {
                        minTime = min(minTime, event.time);
                    };
                };
                minTime;
            };

            var collectEventsAt = { |time|
                var timelineEvent = TimelineEvent();
                params.pairsDo { |param, timeSeq|
                    var event = timeSeq.peek;
                    if (notNil(event)) {
                        if (event.time == time) {
                            timelineEvent[param] = timeSeq.next.binding;
                        };
                    };
                };
                timelineEvent;
            };

            var waitTime;
            var currentTime = findMinTime.();
            var event = collectEventsAt.(currentTime);
            var nextTime = findMinTime.();

            position = currentTime;
            waitTime = (nextTime - position);

            if (notNil(event.speed)) {
                clock.tempo = originalTempo * event.speed;
            };
            cycleSynth.ingestEvent(event);

            (waitTime * length);
        });
    }

    stop {
        clock.clear;
    }
}

TimeSeq {
    var eventStream;
    var peeked;

    *new { |items, stepSize=1|
        var dfs = { |curr, stepSize, totalSteps|
            var currValue = curr.value;
            if (currValue.isKindOf(SequenceableCollection)) {
                var subStepSize = stepSize / currValue.size;
                currValue.do { |binding, i|
                    dfs.(binding, subStepSize, totalSteps);
                };
            } {
                (time: totalSteps.get, binding: currValue).yield;
                totalSteps.value = totalSteps.value + stepSize;
            };
        };
        var eventStream = r {
            var totalSteps = `0;
            loop {
                dfs.(items, stepSize, totalSteps);
            };
        };
        ^super.newCopyArgs(eventStream, nil);
    }

    peek {
        if (notNil(peeked)) {
            ^peeked;
        };
        peeked = this.next;
        ^peeked;
    }

    next {
        if (isNil(peeked)) {
            ^eventStream.next;
        } {
            var tmp = peeked;
            peeked = nil;
            ^tmp;
        };
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
        var nVal = n.value;
        var kVal = k.value;
        var items = (
            (kVal / nVal * (0..nVal - 1))
            .floor
            .differentiate
            .asInteger
            .min(1)[0] = if (kVal <= 0) { 0 } { 1 }
        );
        items = items.rotate(o.value);
        items = items.collect({ |i|
            if (i == 0) { off.value } { on.value }
        });
        ^items;
    }
}