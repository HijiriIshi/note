Vuetifyとvuerouterによるメニュー作成
====

## vue-routerのネストを使ってナビゲーションバーを作る

`App.vue => Navigation.vue => Tweet.vue`というネスト構造を作る場合.

* ポイント1: 各階層の `<router-view />` にマップする.
* ポイント2: `<v-app>`は1つであり、かつ全てのvuetifyコンポ―ネントの親である必要.

```
# App.vue
<template>
  <v-app>
    <router-view />
  </v-app>
</template>
...
```

* ポイント3: メインコンテンツは`<v-content/>`
```
# Navigation.vue
<template>
  <v-app id="inspire">
    <v-navigation-drawer v-model="drawer" app>
    ...
    </v-navigation-drawer>

    <v-app-bar app color="indigo" dark>
      ...
    </v-app-bar>

    <v-footer color="indigo" app>
      ...
    </v-footer>

    <v-content class="fill-height" fluid>
      <router-view />
    </v-content>
  </v-app>
</template>
```

```
# Tweet.vue
<template>
  <v-container class="fill-height" fluid>
    <v-row align="center" justify="center">
      <v-col class="text-center">
        <v-textarea counter label="Text" :value="tweetmessage"></v-textarea>
        <v-file-input
          show-size
          counter
          multiple
          label="File input"
        ></v-file-input>
      </v-col>
    </v-row>
  </v-container>
</template>
```

```
# router/index.ts
const routes = [
  {
    path: "/tweet",
    name: "ツイート",
    component: Navigation,
    children: [{ path: "", component: Tweet }]
  },
] as RouteConfig[];
```

## 名前付きビューを使ってナビゲーションバーを作る
Vue Router の名前付きビューを使うことで、
複数のコンポーネントを一度にルーティングすることができる。

下記の場合`default`のほかに`navigation`がルーティングできる。
```
# App.vue
<template>
  <v-app>
    <router-view class="vue two" name="navigation" />
    <v-content>
      <router-view class="vue one" />
    </v-content>
  </v-app>
</template>
```

* ポイント1: `class`をそれぞれ付けてあげないと一つしか表示されないっぽい。

ルーティング例を以下に示す。
```
// router/index.ts
import { RouteConfig } from 'vue-router';

Vue.use(VueRouter);

const routes = [
  {
    path: "/",
    name: "Home",
    components: {default: Home, navigation: Navigation}
  },
  {
    path: "/login",
    name: "Login",
    component: Login
  }
]  as RouteConfig[];
```

* ポイント1: `routes` は `RouterConfig[]`に明示的にしないとLintでエラーとなる
* ポイント2: `component` ではなく `components` にコンポーネントを設定する。