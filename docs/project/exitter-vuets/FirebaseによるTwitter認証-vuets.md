FirebaseによるTwitter認証
====

## 事前準備
1. Firebase プロジェクト作成
2. Authentication にて Twitter を有効にする
3. Firebase プロジェクトにウェブアプリを登録
   スクリプトが出力される.
   ```
   <!-- The core Firebase JS SDK is always required and must be listed first -->
    <script src="https://www.gstatic.com/firebasejs/7.10.0/firebase-app.js"></script>

    <!-- TODO: Add SDKs for Firebase products that you want to use
        https://firebase.google.com/docs/web/setup#available-libraries -->
    <script src="https://www.gstatic.com/firebasejs/7.10.0/firebase-analytics.js"></script>

    <script>
    // Your web app's Firebase configuration
    var firebaseConfig = {
        apiKey: "*****************************",
        authDomain: "************".firebaseapp.com",
        databaseURL: "https://************".firebaseio.com",
        projectId: "************"",
        storageBucket: "************".appspot.com",
        messagingSenderId: "************"",
        appId: "************"",
        measurementId: "************""
    };
    // Initialize Firebase
    firebase.initializeApp(firebaseConfig);
    firebase.analytics();
    </script>
   ```
4. `npm install firebase`
5. 3.を元に`src/main.ts`に初期化コードを追加
    ```
    import firebase from "firebase"
    // ...
    var firebaseConfig = {
        apiKey: "*****************************",
        authDomain: "************.firebaseapp.com",
        databaseURL: "https://************.firebaseio.com",
        projectId: "************",
        storageBucket: "************.appspot.com",
        messagingSenderId: "************",
        appId: "************",
        measurementId: "************"
    };
    // Initialize Firebase
    firebase.initializeApp(firebaseConfig);
    firebase.analytics();
   ```
6. Twitter Developers側のCallbackURLをFirebaseのハンドラに変更**https://photo-exitter.firebaseapp.com/__/auth/handler**

Note! Firebase Api Key は公開してOK.`<script src="/__/firebase/init.js"></script>`にて参照できるようになっている。

## ログインコード
```
import { Component, Prop, Vue } from "vue-property-decorator";
import firebase from "firebase";
import { OAuthCredential } from "@firebase/auth-types";

@Component
export default class Login extends Vue {
  login() {
    const provider = new firebase.auth.TwitterAuthProvider();
    firebase
      .auth()
      .signInWithPopup(provider)
      .then(
        result => {
          if (!result.credential) {
            return;
          }
          const credential = result.credential as OAuthCredential;
          const token = credential.accessToken;
          const userInfo = result.additionalUserInfo; // Twitter ID等はこちらに格納されている
          const seacret = credential.secret;
          const user = result.user;
          if (user) {
            this.$store.commit("setUser", Object.assign({}, user)); // 値コピー 必要な項目だけ個別に抽出したほうがいいかも
            this.$router.push("/");
          } else {
            alert("有効なアカウントではありません");
          }
        },
        err => {
          alert(err.message);
        }
      );
  }
}
```

Vuex の store
```
import Vue from "vue";
import Vuex from "vuex";
import { User } from "firebase";

Vue.use(Vuex);

interface State {
  user?: User;
}

export default new Vuex.Store({
  state: {
    user: undefined
  } as State,
  getters: {
    user: (state, getters) => {
      return state.user;
    }
  },
  mutations: {
    setUser(state, payload?) {
      state.user = payload;
    }
  },
  actions: {},
  modules: {}
});
```

普通に実行したら
```
Error getting request token: 401 <?xml version='1.0' encoding='UTF-8'?><errors><error code="417">Desktop applications only support the oauth_callback value 'oob'</error></errors>. Return to: https://photo-exitter.firebaseapp.com/__/auth/handler
```

>TwitterでOAuth認証をしようと思ったら
>・PINコードの手入力
>・指定したCallback URLへリダイレクト
>の2通りになると思うのだけど、このうちCallback URLへリダイレクトする方法にしようとしてはまっていた話。
>Twitter側でアプリケーションを登録する際にApplication Typeを選択できる。ここで、Browserを選択するとCallback URLを指定できる。
>ところが、OAuthの仕様上、oauth_callbackとかいうヘッダをつけて実際にリクエストするときに指定できるので、アプリケーションの登録時には別に空白でよいかと思っていた。
>そうすると、何度試してもリクエストトークンを取得する最初の段階で 401 OAuth.Unauthorized が発生するのだった。
?>obというのは out-of-band のことで、デスクトップアプリケーションだとPINコードを入力する方法しかダメだよ！と言っている。
>「そんな馬鹿な。ちゃんとBrowserを選んだじゃないか。」と思って確認しに行くとなぜか Client 指定ですよ。どうやらアプリケーション登録時に Callback URL を指定しなければ自動的に Client のほうへ変更されてしまうらしい。
>Callback URL自体は適当に指定していても、リクエスト時のパラメータを使ってくれるようなので、とりあえず埋めておけばよさそう。
http://speg03.hatenadiary.jp/entry/20091019/1255957580

適当に自分のTwitterURLをCallbackに入れたらエラーメッセージが変化
```
Error getting request token: 403 <?xml version='1.0' encoding='UTF-8'?><errors><error code="415">Callback URL not approved for this client application. Approved callback URLs can be adjusted in your application settings</error></errors>. Return to: https://photo-exitter.firebaseapp.com/__/auth/handler
```

```
2018年6月13日以降はAPIを使用するアプリ側できちんとcallback時のURLを設定する必要があります。
アカウントを連携する時に返ってくるURLになります。

ちなみに開発環境においては、 localhostはNGでしたが、Vagrantで使用しているIPを使ってもOKでした。

実際のアプリでは正しくURLを指定する必要があります。
つまりoauth/request_tokenをリクエストする時のoauth_callbackパラメータに入るurlを、Twitterの開発アカウントの設定画面のcallbackURLで設定したURLと一致していないとダメになりました。
```

Firebaseにて認証してるため、エラーメッセージ内にもある
**https://photo-exitter.firebaseapp.com/__/auth/handler**
にすればOK.