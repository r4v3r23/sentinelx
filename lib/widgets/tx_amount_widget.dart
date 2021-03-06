import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinelx/shared_state/rate_state.dart';

class AmountWidget extends StatefulWidget {
  final num result;
  TextStyle style = new TextStyle();
  TextAlign align = TextAlign.start;
  double height = 40;

  @override
  _AmountWidgetState createState() => _AmountWidgetState();

  AmountWidget(this.result, {this.style, this.height, this.align});
}

class _AmountWidgetState extends State<AmountWidget> with SingleTickerProviderStateMixin {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = new PageController(initialPage: RateState().index, keepPage: true, viewportFraction: 0.89);
    init();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (RateState().index == 2) {
          RateState().setViewIndex(0);
        } else {
          RateState().setViewIndex(RateState().index + 1);
        }
      },
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: BouncingScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, position) {
              if (position == 0) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "${RateState().formatToBTCRate(widget.result)}",
                      style: widget.style,
                      textAlign: widget.align,
                    ),
                  ],
                );
              }
              if (position == 1) {
                return Consumer<RateState>(builder: (context, model, c) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${model.formatRate(widget.result)}",
                        style: widget.style,
                        textAlign: widget.align,
                      ),
                    ],
                  );
                });
              } else {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "${RateState().formatSatRate(widget.result)}",
                      style: widget.style,
                      textAlign: widget.align,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  void init() async {

    RateState().addListener(() {
      if (_pageController.hasClients && RateState().index < 3 && RateState().index >= 0) {
        _pageController.animateToPage(RateState().index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    });
  }
}
