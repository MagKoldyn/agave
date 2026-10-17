const test = require('node:test');
const assert = require('node:assert/strict');
const Core = require('../src/core.js');
test('полный цикл посадки, роста и сбора',()=>{const s=Core.initialState();assert.equal(Core.plant(s,0),true);assert.equal(Core.water(s,0),true);Core.endDay(s);assert.equal(s.plots[0].state,Core.SPROUT);assert.equal(Core.water(s,0),true);Core.endDay(s);assert.equal(s.plots[0].state,Core.MATURE);assert.equal(Core.harvest(s,0),true);assert.equal(s.harvest,1)});
test('ресурсы не уходят при недоступном действии',()=>{const s=Core.initialState();assert.equal(Core.water(s,0),false);assert.equal(s.water,6);assert.equal(Core.harvest(s,0),false)});
test('продажа совпадает с превью экономики',()=>{const s=Core.initialState();s.harvest=3;assert.equal(Core.sell(s),42);assert.equal(s.coins,82);assert.equal(s.harvest,0)});
test('квест отражает прогресс',()=>{const s=Core.initialState();assert.match(Core.questInfo(s).text,/Лусию/);s.metLucia=true;s.planted=3;s.watered=3;s.gathered=3;assert.match(Core.questInfo(s).text,/рыночный/);s.sold=3;assert.equal(Core.questInfo(s).progress,1)});
