Def {
    var name, params, head;

    *new { |name|
        if (ProxySpace.all[name] == nil) { 
            ProxySpace(Server.default, name, TempoClock.default);
        };
        ^super.newCopyArgs(name, Dictionary[]);
    }

    in { |iName| 
        this.register(\in, iName);
    }

    register { |key, synthName=nil|
        var proxy = ProxySpace.all[name];
        proxy[key] = (synthName ? key);
        proxy[key].controlKeys.do { |k|
            params[k] = key;
        };
        proxy[key].reshaping = \elastic;
        if (head == nil) {
            head = key;
        }
    }
    
    snake { |key|
        var proxy = ProxySpace.all[name];
        this.register(key);
        proxy[head] <>> proxy[key];
        proxy[\out] <-- proxy[key];
        head = key;
    }

    /*
     * Generates a unique name given the symbol
     */
    genName { |sym, ns=nil|
        ns = ns ? name;
        ^(ns.asString ++ "_" ++ sym.asString).asSymbol
    }

    on { |pat|
        var durs, vals, proxy;
        
        proxy = ProxySpace.all[name];

        #vals, durs = SPMini.durVals(pat);

        Tdef(this.genName(\in), {
            inf.do { |i| 
                proxy[\in].spawn;
                (1/4).wait;
            }
        }).play;

        if (not(proxy[\out].isPlaying)) {
            proxy[\out] = { proxy[head].ar };
            proxy[\out].play;
        };
    }

    setIn { |param, ctl|
        var proxy = ProxySpace.all[name],
            parent = params[param],
            // produces: parent_param
            pname = this.genName(param, parent),
            // produces: name_parent_param
            tname = this.genName(pname);

        if (ctl.isKindOf(String)) {
            var vals, durs;
            #vals, durs = SPMini.durVals(ctl);

            proxy[pname].clear;
            
            Tdef(tname, {
                inf.do { |i|
                    var dur = durs.wrapAt(i).value;
                    proxy[parent].set(param, vals.wrapAt(i).value);
                    dur.wait;
                }
            }).play;
        } {
            Tdef(tname).stop;
            proxy[pname] = ctl;
            proxy[parent].set(param, proxy[pname]);
        };
    }

    doesNotUnderstand { |selector ...args|
        this.setIn(selector, args[0]);
    }
}
