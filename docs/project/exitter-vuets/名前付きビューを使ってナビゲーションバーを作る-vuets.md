名前付きビューを使ってナビゲーションバーを作る
====

Vue Router の名前付きビューを使うことで、
複数のコンポーネントを一度にルーティングすることができる。

下記の場合`default`のほかに`navigation`がルーティングできる。
```html
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
```typescript
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