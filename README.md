# VRChatOptionalBoot
VRChat のログインオプションをGUIで取り扱い易くしたツール。
Powershell スクリプトで作成しているため容易に自分用に修正が可能です。

## 起動イメージ
![image](https://user-images.githubusercontent.com/60001124/85929808-bb2b6080-b8f2-11ea-96c6-77032ac2e31d.png)

## License
MIT License

## 使い方
1. リポジトリのトップページから [Clone or download]-[Download ZIP] を選択してダウンロード
2. ダウンロードしたファイルを解凍(展開)
3. フォルダ内の Initialize.bat を起動(*1)
4. 同階層又はスタートメニューに登録したショートカットから起動
5. オプションを指定して VRChat を起動

*1 下記警告が表示された場合は [詳細情報] を選択してから [実行]<br />
   ![image](https://user-images.githubusercontent.com/11162845/81124200-d1124a00-8f6f-11ea-9ec5-2bd54186167c.png)

## オプション一覧
| head1 | head2 |
| ----- | ----- |
| Desktop Mode(--no-vr) | デスクトップモードで起動する |
| Oculus Rift | Oculus でコントローラが上手く使えなくなる場合があるため関連するアプリケーションを段階的に起動する |
| Use GUI Debug Window(--enable-debug-gui) | `Shift+@+3` 等のデバッグ表示を有効にする |
| Use Detail (for SDK2) Debug Logging(--enable-sdk-log-levels) | SDK2用の詳細なデバッグ情報の出力を有効にする |
| Use Detail UDON Debug Logging(--enable-udon-debug-logging) | UDON用の詳細なデバッグ情報の出力を有効にする |
| World ID(Empty:Go Home World) | World ID を指定して起動する(空の場合はホームで起動) |
| Profile0-3 | 特定のプロファイルで起動する |
| Boot VRChat | 上記設定で VRChat を起動する |

## その他の機能

* 好きなアイコンを vrchat_optional_boot.ico という名前でスクリプトフォルダに配置して Intialize.bat の実行することで、ショートカットに任意のアイコンを設定できる(naqtnさん追加)

## 参照
* Initialize.bat に関する画像<br />
  https://gist.github.com/naqtn/5153bb357c92689993e23d1b6c91505d
* PowerShellメモ　GUIの入力画面を表示(XAML) - Qiita<br />
  https://qiita.com/Kosen-amai/items/27647f0a1ea5b41a9f5c
* VRChat ローカルテスト起動補助スクリプト / VRChat LocalTest launch aid script - - BOOTH<br />
  https://kamishirolab.booth.pm/items/1954145
* Windows 7 - ショートカットをコピーするbatファイルを作りたいです。｜teratail<br />
  https://teratail.com/questions/57372
* VBS：ショートカットファイルの作成 - プチエンジニアの備忘録的なあれこれ<br />
  http://marazul2015.blog.fc2.com/blog-entry-39.html
* naqtn(なくとん)さんはTwitterを使っています 「@vrctaki アイコンが拡張子違いで存在したらそれ...<br />
  https://twitter.com/naqtn/status/1257659359573635075
* Powercli/Powershell GUI Placeholder textbox example at master  kunaludapi/Powercli<br />
  https://github.com/kunaludapi/Powercli/tree/master/Powershell%20GUI%20Placeholder%20textbox%20example
* 作成初期のツイート&スレッド<br />
  https://twitter.com/vrctaki/status/1257567286698766336


