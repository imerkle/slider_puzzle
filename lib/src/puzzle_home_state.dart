import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:js/js.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_state.dart';
import 'core/puzzle_animator.dart';
import 'frame_nanny.dart';
import 'shared_theme.dart';
import 'theme_plaster.dart';

import 'js_interop/arweave.dart';
import 'js_interop/console.dart';
import 'js_interop/json.dart';

var appName = "slider_puzzle";


class Score {
  String address;
  String moves;
  String tiles;

  Score({this.address, this.moves, this.tiles});

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      address: json['address'] as String,
      moves: json['moves'] as String,
      tiles: json['tiles'] as String,
    );
  }
}

final tstyle = TextStyle(color: Color(0xffcccccc));

final theader = TextStyle(color: Color(0xffcccccc), fontWeight: FontWeight.bold, fontSize: 18);
class PuzzleHomeState extends State
    with TickerProviderStateMixin
    implements AppState {
  TabController _tabController;
  AnimationController _controller;
  Animation<Offset> _shuffleOffsetAnimation;

  @override
  Animation<Offset> get shuffleOffsetAnimation => _shuffleOffsetAnimation;

  
  List<Score> scores = [];

  @override
  final PuzzleAnimator puzzle;

  @override
  final animationNotifier = _AnimationNotifier();

  @override
  TabController get tabController => _tabController;

  final _nanny = FrameNanny();

  SharedTheme _currentTheme;

  @override
  SharedTheme get currentTheme => _currentTheme;

  @override
  set currentTheme(SharedTheme theme) {
    setState(() {
      _currentTheme = theme;
    });
  }

  Duration _tickerTimeSinceLastEvent = Duration.zero;
  Ticker _ticker;
  Duration _lastElapsed;
  StreamSubscription sub;

  @override
  bool autoPlay = false;


  init arweave = init();
  String address;
  final walletKeyController = TextEditingController();
  
  PuzzleHomeState(this.puzzle) {
    sub = puzzle.onEvent.listen(_onPuzzleEvent);

    _themeDataCache = List.unmodifiable([
      //ThemeSimple(this),
      //ThemeSeattle(this),
      ThemePlaster(this),
    ]);

    _currentTheme = themeData.first;
  }

  @override
  void initState() {
    super.initState();
    _ticker ??= createTicker(_onTick);
    _ensureTicking();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _shuffleOffsetAnimation = _controller.drive(const _Shake());
    _tabController = TabController(vsync: this, length: _themeDataCache.length);

    _tabController.addListener(() {
      currentTheme = _themeDataCache[_tabController.index];
    });




    //walletKeyController.text = '';
    search();
    // Start listening to changes.

    walletKeyController.addListener(()=>{
      setAddress()
    });

  }


  List<SharedTheme> _themeDataCache;

  @override
  Iterable<SharedTheme> get themeData => _themeDataCache;

  @override
  void setAutoPlay(bool newValue) {
    if (newValue != autoPlay) {
      setState(() {
        // Only allow enabling autoPlay if the puzzle is not solved
        autoPlay = newValue && !puzzle.solved;
        if (autoPlay) {
          _ensureTicking();
        }
      });
    }
  }



  void setAddress() async{
    if (walletKeyController.text.length > 0) {
      var a = await promiseToFuture(arweave.wallets.jwkToAddress(parse(walletKeyController.text)));
      setState((){
        address = a;
      });
    }
  }
  void submit() async{
    var w = parse(walletKeyController.text);
    var a = await promiseToFuture(arweave.wallets.jwkToAddress(w));

    var t = await promiseToFuture(arweave.createTransaction(Data(data: '{"moves":"${puzzle.clickCount}", "tiles": "${puzzle.incorrectTiles}", "address": "$a"}'), w));
    t.addTag("appName", appName);
    t.addTag("kind", "score");
    await promiseToFuture(arweave.transactions.sign(t,w));
    await promiseToFuture(arweave.transactions.post(t));
    Scaffold.of(context).showSnackBar(SnackBar(content: Text('Submitted on Blockchain!'))); 
  }
  void search() async {
    var a = '{"op": "and","expr1": {"op": "equals", "expr1": "appName","expr2": "$appName"},"expr2": {"op": "equals", "expr1": "kind", "expr2": "score"}}';

    var transactions = await promiseToFuture(arweave.arql(parse(a)));
    List<Score> s = [];
    for (var t in transactions){
      var x = await promiseToFuture(arweave.transactions.get(t));
      var j = Score.fromJson(json.decode(x.get("data", TxOpts(decode: true, string: true))));
      s.add(j);
    }
    //s.add(Score(address: "testaddr", moves: "100", tiles: "13"));
    //s.add(Score(address: "testaddr", moves: "500", tiles: "5"));
    //s.add(Score(address: "testaddr", moves: "321", tiles: "5"));
    s.sort((a, b){
        var r = int.parse(a.tiles).compareTo(int.parse(b.tiles));
        if (r != 0) return r;
        return int.parse(a.moves).compareTo(int.parse(b.moves));
      } 
    );
    setState(() {
      scores = s;
    });

    
  }
  
  @override
  Widget build(BuildContext context){
    return Row(
            children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Material(
                    color: const Color(0xff424244),
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Arweave Keyfile Json",
                            style: theader
                          ),
                          Text( address ?? "",
                            style: tstyle
                          ),
                          TextField(
                              controller: walletKeyController,
                              maxLines: 8,
                              decoration: InputDecoration(
                                hintText: 'Enter your keyfile json here'
                            ),                  
                          ),
                          RaisedButton(
                            child: Text("Submit Score"),
                            onPressed: (){
                              submit();
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 30),
                            child: Text("High Scores",
                              style: theader,
                            ),
                          ),                   
                          Expanded(
                            child: ListView.builder(
                              itemCount: scores.length,
                              itemBuilder: (BuildContext ctxt, int index) {
                                return Container(
                                  color: const Color(0xff1b1b1b),
                                  margin: const EdgeInsets.only(top: 20),
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                        Text("Address: ${scores[index].address}", 
                                        overflow: TextOverflow.fade, style: tstyle),
                                        Text("Tiles Remaining: ${scores[index].tiles}", style: tstyle),
                                        Text("Moves: ${scores[index].moves}", style: tstyle),
                                    ],
                                  ),
                                );
                              }                            
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _currentTheme.build(context),
                )
            ],
          )
    ;
  }

  @override
  void dispose() {
    animationNotifier.dispose();
    _tabController.dispose();
    _controller?.dispose();
    _ticker?.dispose();
    sub.cancel();
    walletKeyController.dispose();    

    super.dispose();
  }

  void _onPuzzleEvent(PuzzleEvent e) {
    _tickerTimeSinceLastEvent = Duration.zero;
    _ensureTicking();
    if (e == PuzzleEvent.noop) {
      assert(e == PuzzleEvent.noop);
      _controller.reset();
      _controller.forward();
    }
    setState(() {
      // noop
    });
  }

  void _ensureTicking() {
    if (!_ticker.isTicking) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    if (elapsed == Duration.zero) {
      _lastElapsed = elapsed;
    }
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    if (delta.inMilliseconds <= 0) {
      // `_delta` may be negative or zero if `elapsed` is zero (first tick)
      // or during a restart. Just ignore this case.
      return;
    }

    _tickerTimeSinceLastEvent += delta;
    puzzle.update(_nanny.tick(delta));

    if (!puzzle.stable) {
      animationNotifier.animate();
    } else {
      if (!autoPlay) {
        _ticker.stop();
        _lastElapsed = null;
      }
    }

    if (autoPlay &&
        _tickerTimeSinceLastEvent > const Duration(milliseconds: 200)) {
      puzzle.playRandom();

      if (puzzle.solved) {
        setAutoPlay(false);
      }
    }
  }
}

class _Shake extends Animatable<Offset> {
  const _Shake();

  @override
  Offset transform(double t) => Offset(0.01 * math.sin(t * math.pi * 3), 0);
}

class _AnimationNotifier extends ChangeNotifier implements AnimationNotifier {
  _AnimationNotifier();

  @override
  void animate() {
    notifyListeners();
  }
}


Future<dynamic> promiseToFuture(Promise x) async{
    final completer = new Completer<dynamic>();
    x.then(allowInterop(completer.complete), allowInterop(completer.completeError));
    return completer.future;
}