import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinelx/models/wallet.dart';
import 'package:sentinelx/shared_state/balance.dart';
import 'package:sentinelx/utils/format_util.dart';
import 'package:sentinelx/widgets/tx_amount_widget.dart';

class BalanceCardWidget extends StatefulWidget {
//  XPUBModel model;
//
//  CardWidget(this.model);

  @override
  _BalanceCardWidgetState createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
  @override
  Widget build(BuildContext context) {
//    final counter =;
    final Wallet wallet = Provider.of<Wallet>(context);
    return Stack(
      children: <Widget>[
        Card(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "Total",
                        maxLines: 1,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ChangeNotifierProvider<BalanceModel>.value(
                      value: wallet.balanceModel,
                      child: Consumer<BalanceModel>(
                        builder: (context, model, c) {
                          return AmountWidget(
                            model.balance,
                            style:    TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold),
                            height: 100,
                          );
//                          return Text(
//                            "BTC ${satToBtc(model.balance)}",
//                            maxLines: 1,
//                            textAlign: TextAlign.start,
//                            overflow: TextOverflow.ellipsis,
//                            style: TextStyle(
//                                fontSize: 26, fontWeight: FontWeight.bold),
//                          );
                        },
                      ),
                    ),
                  ),
                ),
                Spacer(flex: 1)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
