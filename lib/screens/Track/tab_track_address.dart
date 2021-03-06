import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentinelx/channels/crypto_channel.dart';
import 'package:sentinelx/models/wallet.dart';
import 'package:sentinelx/models/xpub.dart';
import 'package:sentinelx/shared_state/app_state.dart';
import 'package:sentinelx/widgets/qr_camera/push_up_camera_wrapper.dart';
import 'package:sentinelx/widgets/sentinelx_icons.dart';

class TabTrackAddress extends StatefulWidget {
  final GlobalKey<PushUpCameraWrapperState> cameraKey;

  @override
  TabTrackAddressState createState() => TabTrackAddressState();

  TabTrackAddress(Key key, this.cameraKey) : super(key: key);
}

class TabTrackAddressState extends State<TabTrackAddress> {
  TextEditingController _labelEditController;
  TextEditingController _xpubEditController;

  @override
  void initState() {
    _labelEditController = TextEditingController();
    _xpubEditController = TextEditingController();
    super.initState();
    this.widget.cameraKey.currentState.setDecodeListener((val) {
      _xpubEditController.text = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
      margin: const EdgeInsets.only(top: 54),
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Row(
              children: <Widget>[
                Icon(
                  SentinelxIcons.bitcoin,
                  size: 32,
                  color: Colors.grey[400],
                ),
                Container(
                    margin: EdgeInsets.only(left: 12),
                    child: Text(
                      "Track Single bitcoin address",
                      style: TextStyle(color: Colors.grey[400]),
                    ))
              ],
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: TextField(
                  controller: _labelEditController,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: "Label",
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: TextField(
                  controller: _xpubEditController,
                  decoration: InputDecoration(
                    labelText: "Enter bitcoin address",
                  ),
                  maxLines: 1,
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                    icon: Icon(
                      SentinelxIcons.qr_scan,
                      size: 22,
                    ),
                    onPressed: () async {
                      await SystemChannels.textInput
                          .invokeMethod('TextInput.hide');
                      widget.cameraKey.currentState.start();
                    }),
              )
            ],
          )
        ],
      ),
    );
  }

  validateAndSaveAddress() async {
    String label = _labelEditController.text;
    String xpubOrAddress = _xpubEditController.text;

    if (Provider.of<AppState>(context)
        .selectedWallet
        .doesXPUBExist(xpubOrAddress)) {
      _showError("Address already exist");
      return;
    }

    try {
      bool valid = await CryptoChannel().validateAddress(xpubOrAddress);
      if (!valid) {
        _showError('Invalid Bitcoin address');
      } else {
        XPUBModel xpubModel =
            XPUBModel(xpub: xpubOrAddress, bip: "ADDR", label: label);
        Wallet wallet = AppState().selectedWallet;
        wallet.xpubs.add(xpubModel);
        await wallet.saveState();
        int index = wallet.xpubs.indexOf(xpubModel);
        _showSuccessSnackBar("Address added successfully");
        AppState().setPageIndex(index);
        Timer(Duration(milliseconds: 700), () {
          if (Navigator.canPop(context)) {
            Navigator.pop<int>(context, index);
          }
        });
      }
    } catch (exc) {
      _showError('Invalid Bitcoin address');
    }
  }

  void _showSuccessSnackBar(String msg) {
    final snackBar = SnackBar(
      content: Text(msg),
      backgroundColor: Color(0xff5BD38D),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _showError(String msg) {
    final snackBar = SnackBar(
      content: Text(msg),
      backgroundColor: Color(0xffD55968),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
