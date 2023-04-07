近くの営業中の飲食店検索アプリ
このアプリは、ユーザーの現在地から一定の範囲内で営業中の飲食店を探し、Googleマップ上にピンを立てて表示する機能を提供します。サウナやスポーツジムから出た後に、近くの営業中の飲食店を探すのに便利です。Flutterを使用して開発されているため、iOSやAndroidなど、複数のプラットフォームで動作するアプリを効率的に開発できます。

スクリーンショット

https://user-images.githubusercontent.com/100826002/230542240-b7fa3813-5527-491e-90e7-a1620cb5b6e8.mov


機能
位置情報の取得と許可
営業中の飲食店の検索
地図上にピンを立てる
カスタムマップスタイル
範囲選択ボタン
現在地ボタン
お店の詳細情報へのリンク
環境構築
Flutter SDKのインストール: 公式ドキュメントに従って、Flutter SDKをインストールしてください。
依存関係のインストール: pubspec.yamlに記載されたパッケージをインストールするために、プロジェクトディレクトリでflutter pub getコマンドを実行してください。
Google Maps APIキーの取得: 公式ドキュメントに従って、Google Maps APIキーを取得してください。
APIキーの設定: 取得したAPIキーをAndroidManifest.xml（Android）およびAppDelegate.swift（iOS）に設定してください。
アプリの実行
エミュレータや実機を準備してください。
プロジェクトディレクトリでflutter runコマンドを実行してアプリを起動します。
使用方法
アプリを起動すると、現在地周辺の営業中の飲食店が表示されます。
画面下部のボタンを押すことで、検索範囲を変更できます（100m、250m、500m）。
画面下部の現在地アイコンを押すことで、地図上で現在地に戻ることができます。
ピンのインフォウィンドウをタップすると、Googleマップのお店の詳細ページが開きます。
サポートと貢献
バグを見つけた場合や新機能のリクエストがある場合は、GitHubのissueページに報告してください。また、プルリクエストも歓迎します。

開発者について
このアプリは、Flutterエンジニアの佐藤海斗によって開発されました。ご質問やご意見があれば、お気軽にお問い合わせください。



今後の予定
お気に入り機能の追加
お店の評価や写真をアプリ内で表示
レストランのフィルタリング機能
ダークモード対応
地図上でルート案内の実装
このアプリをお楽しみいただければ幸いです。どんなフィードバックでも歓迎しますので、お気軽にお寄せください。
