(

~tdAddrs = Dictionary.new;

~tdAddrs['2'] = NetAddr("127.0.0.1", 57130);
~tdAddrs['3'] = NetAddr("127.0.0.1", 57131);
~tdAddrs['5'] = NetAddr("127.0.0.1", 57132);
~tdAddrs['6'] = NetAddr("127.0.0.1", 57133);

~kickCounter = 0;

OSCdef(\tdSend, {
    arg msg;

    var dict, addr, id;
    dict = Dictionary.new;

    msg = msg.drop(1);
    msg = msg.clump(2);

    msg.do({
        arg pair;
        if (pair.size == 2, {
            dict.put(pair[0], pair[1]);
        }, {
            "Warning: Incomplete pair found: %".format(pair).warn;
        });
    });

    id = dict['_id_'];
    addr = ~tdAddrs[id];
    if (id == '2', {
        addr.sendMsg(\delayfeedback, dict[\delayfeedback]);
        addr.sendMsg(\n, dict[\n]);
    });
    if (id == '3', {
        addr.sendMsg(\red, 1.0.rand);
        addr.sendMsg(\green, 1.0.rand);
        addr.sendMsg(\blue, 1.0.rand);
        addr.sendMsg(\noiseseed, 256.rand);
    });
    if (id == '5', {
        addr.sendMsg(\distort, dict[\distort].linlin(0.2, 1.1, 0, 1.0));
    });
    if (id == '6', {
        addr.sendMsg(\horzsource, 9.rand);
        addr.sendMsg(\vertsource, 9.rand);
    });
}, '/dirt/play');

)

OSCdef(\tdSend).free;