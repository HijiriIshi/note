mapStateを使ってVuexの状態をMapする
====

Typescriptだとちょいめんどい。

以下の `State` を扱う場合、
```typescript
// store/index.ts
import Vue from "vue";
import Vuex from "vuex";
import { User } from "firebase";

Vue.use(Vuex);

export interface State {
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

```typescript
// Navigation.vue
import { Component, Vue} from "vue-property-decorator";
import { mapState } from 'vuex';
import { State } from '@/store/index.ts';

@Component({
    computed: mapState<State>({
        userName: (state: State) => state.user && state.user.displayName,
        photoURL: (state: State)  => state.user && state.user.photoURL,
    })
})
export default class Navigation extends Vue {

    userName?: string;

    photoURL?: string;

```

もしかしたら `@Component` は以下のほうが正道かも
```typescript
@Component({
    computed: mapState({
        userName: (state: any, getter: State) => getter.user && getter.user.displayName,
        photoURL: (state: any, getter: State)  => getter.user && getter.user.photoURL,
    })
})
```