import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sentinelx/channels/api_channel.dart';
import 'package:sentinelx/models/db/prefs_store.dart';
import 'package:sentinelx/models/db/tx_db.dart';
import 'package:sentinelx/models/exchange/LocalBitcoinRateProvider.dart';
import 'package:sentinelx/models/exchange/exchange_provider.dart';
import 'package:sentinelx/models/exchange/rate.dart';
import 'package:sentinelx/models/tx.dart';
import 'package:sentinelx/models/unspent.dart';
import 'package:sentinelx/models/wallet.dart';
import 'package:sentinelx/models/xpub.dart';
import 'package:sentinelx/shared_state/loaderState.dart';
import 'package:sentinelx/shared_state/rate_state.dart';
import 'package:sentinelx/shared_state/theme_provider.dart';
import 'package:sentinelx/utils/utils.dart';

class AppState extends ChangeNotifier {
  AppState._privateConstructor();

  TxDB txDB;

  static final AppState _instance = AppState._privateConstructor();

  factory AppState() {
    return _instance;
  }

  List<Wallet> wallets = [];
  Wallet selectedWallet = Wallet(walletName: "WalletSTUB", xpubs: []);
  bool isTestNet = false;
  Rate selectedRate;
  ExchangeProvider exchangeProvider;
  ThemeProvider theme = ThemeProvider();
  int pageIndex = 0;
  bool offline = false;
  LoaderState loaderState = LoaderState();

  selectWallet(Wallet wallet) {
    this.selectedWallet = wallet;
    notifyListeners();
  }

  Future refreshTx(int index) async {
    try {
      String xpub = this.selectedWallet.xpubs[index].xpub;
      loaderState.setLoadingStateAndXpub(States.LOADING, xpub);

      String response = await ApiChannel().getXpubOrAddress(xpub);
      Map<String, dynamic> json = await compute(parseJsonResponse, response);
      if (json.containsKey("addresses")) {
        List<dynamic> items = json['addresses'];
        var balance = 0;
        if (json.containsKey("wallet")) {
          balance = json['wallet']['final_balance'];
        }
        if (items.length == 1) {
          Map<String, dynamic> address = items.first;
          var addressObj = await compute(parse, address);
          AppState().selectedWallet.updateXpubState(addressObj, balance);
          if (json.containsKey("txs")) {
            List<dynamic> txes = json['txs'];
            await TxDB.insertOrUpdate(txes, addressObj, true);
//            final count = this.selectedWallet.xpubs.length == 0 ? 1 : this.selectedWallet.xpubs.length + 2;
            if (pageIndex == 0 ||
                pageIndex > this.selectedWallet.xpubs.length - 1) {
              setPageIndex(0);
            } else {
              setPageIndex(pageIndex);
            }
            loaderState.setLoadingStateAndXpub(States.COMPLETED, "all");
            return;
          }
        }
      }
      loaderState.setLoadingStateAndXpub(States.COMPLETED, "all");
    } catch (e) {
      loaderState.setLoadingStateAndXpub(States.COMPLETED, "all");
      print("E $e");
      throw e;
    }
  }

  Future getUnspent() async {
    try {
      List<String> xpubsAndAddresses =
          selectedWallet.xpubs.map((item) => item.xpub).toList();
      var response = await ApiChannel().getUnspent(xpubsAndAddresses);
      Map<String, dynamic> json = jsonDecode(response);
      if (json.containsKey("unspent_outputs")) {
        List<dynamic> items = json['unspent_outputs'];
        List<Unspent> unspent =
            items.map((item) => Unspent.fromJson(item)).toList();
        await TxDB.insertOrUpdateUnspent(unspent);
      }
    } catch (e) {
      print("E $e");
    }
  }

  void setPageIndex(int index) async {
    pageIndex = index;
    notifyListeners();
    if (pageIndex == 0) {
      this
          .selectedWallet
          .txState
          .addTxes(await TxDB.getAllTxes(this.selectedWallet.xpubs));
      return;
    }
    if ((this.selectedWallet.xpubs.length < pageIndex)) {
      return;
    } else {
      String xpub = this.selectedWallet.xpubs[index - 1].xpub;
      this.selectedWallet.txState.addTxes(await TxDB.getTxes(xpub));
    }
    notifyListeners();
  }

  void updateTransactions(String address) async {
    XPUBModel xpubModel =
        this.selectedWallet.xpubs.firstWhere((item) => item.xpub == address);
    if (this.pageIndex == this.selectedWallet.xpubs.indexOf(xpubModel)) {
      this.selectedWallet.txState.addTxes(await TxDB.getTxes(xpubModel.xpub));
    }

    if (this.pageIndex == 0) {}
  }

  Future clearWalletData() async {
    await PrefsStore().clear();
    await selectedWallet.clear();
  }

  static Address parse(Map<String, dynamic> addressObjs) {
    return Address.fromJson(addressObjs);
  }
}
