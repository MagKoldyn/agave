(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api; else root.AgaveCore = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  const EMPTY = 0, PLANTED = 1, SPROUT = 2, MATURE = 3;
  function makePlot(index) { return { index, state: EMPTY, watered: false, age: 0 }; }
  function initialState() { return { version: 1, day: 1, minute: 360, coins: 40, water: 6, seeds: 6, harvest: 0, planted: 0, watered: 0, gathered: 0, sold: 0, metLucia: false, branchHint: null, plots: Array.from({ length: 20 }, (_, i) => makePlot(i)) }; }
  function plant(state, index) { const p=state.plots[index]; if(!p||p.state!==EMPTY||state.seeds<1)return false; p.state=PLANTED;p.age=0;p.watered=false;state.seeds--;state.planted++;return true; }
  function water(state, index) { const p=state.plots[index]; if(!p||p.state===EMPTY||p.watered||state.water<1)return false; p.watered=true;state.water--;state.watered++;return true; }
  function harvest(state, index) { const p=state.plots[index]; if(!p||p.state!==MATURE)return false; p.state=EMPTY;p.age=0;p.watered=false;state.harvest++;state.gathered++;return true; }
  function refill(state) { state.water=6; }
  function sell(state) { const amount=state.harvest;state.harvest=0;state.sold+=amount;state.coins+=amount*14;return amount*14; }
  function endDay(state) { state.plots.forEach(p=>{if(p.state!==EMPTY&&p.watered){p.age++;p.state=p.age>=2?MATURE:SPROUT}p.watered=false});state.day++;state.minute=360;state.water=6;return state; }
  function questInfo(state) {
    if(!state.metLucia)return{title:'Пыль на пороге',text:'Найдите Лусию у старого колодца.',progress:0};
    if(state.planted<3)return{title:'Первые корни',text:`Посадите три агавы (${state.planted}/3).`,progress:state.planted/3};
    if(state.watered<3)return{title:'Память воды',text:`Полейте молодые агавы (${state.watered}/3).`,progress:state.watered/3};
    if(state.gathered<3)return{title:'Терпение земли',text:`Вырастите и соберите урожай (${state.gathered}/3). Завершайте дни у дома.`,progress:state.gathered/3};
    if(state.sold<3)return{title:'Цена урожая',text:'Отнесите агаву на рыночный прилавок.',progress:.8};
    return{title:'Шёпот под землёй',text:'Вернитесь к Лусии. Сердце проснулось.',progress:1};
  }
  return { EMPTY, PLANTED, SPROUT, MATURE, initialState, plant, water, harvest, refill, sell, endDay, questInfo };
});
