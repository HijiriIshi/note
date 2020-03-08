プロジェクトの作成
====

* typescript(3.7.5)
* vue.ts(@vue/cli 4.2.3)
* vuetify(2.2.15)

1. `vue/cli`導入 `npm install -g @vue/cli`
2. `vue create sample1`
3. `cd sample1` => `vue add vuetify`
4. `tsconfig.json`に`"vuetify"`を追記
```
    "types": [
      "webpack-env",
      "jest",
      "vuetify"
    ],
```