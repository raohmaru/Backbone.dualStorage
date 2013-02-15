// Generated by CoffeeScript 1.3.3
(function() {
  var Backbone, collection, model, spyOnLocalsync, window, _, _ref;

  window = require('./spec_helper').window;

  Backbone = window.Backbone;

  _ = window._;

  _ref = {}, collection = _ref.collection, model = _ref.model;

  beforeEach(function() {
    window.onlineSync.calls = [];
    window.localStorage.clear();
    collection = new Backbone.Collection({
      id: 12,
      position: 'arm'
    });
    collection.url = 'bones/';
    delete collection.remote;
    model = collection.models[0];
    return delete model.remote;
  });

  spyOnLocalsync = function(spec) {
    var coffee;
    coffee = require('coffee-script');
    runs(function() {
      return coffee["eval"]("window.oldLocalsync = window.localsync; window.localsync = jasmine.createSpy('localsync').andCallFake((method, model, options) -> (options.success?()) unless options.ignoreCallbacks)", {
        sandbox: window
      });
    });
    runs(function() {
      return spec(window.localsync);
    });
    return runs(function() {
      return coffee["eval"]("window.localsync = window.oldLocalsync", {
        sandbox: window
      });
    });
  };

  describe('delegating to localsync and onlineSync, and calling the model callbacks', function() {
    describe('dual tier storage', function() {
      describe('create', function() {
        return it('delegates to both localsync and onlinesync', function() {
          return spyOnLocalsync(function() {
            var ready;
            ready = false;
            runs(function() {
              return window.dualsync('create', model, {
                success: (function() {
                  return ready = true;
                })
              });
            });
            waitsFor((function() {
              return ready;
            }), "The success callback should have been called", 100);
            return runs(function() {
              expect(window.onlineSync).toHaveBeenCalled();
              expect(window.onlineSync.calls[0].args[0]).toEqual('create');
              expect(window.localsync).toHaveBeenCalled();
              return expect(window.localsync.calls[0].args[0]).toEqual('create');
            });
          });
        });
      });
      describe('read', function() {
        return it('delegates to both localsync and onlinesync', function() {
          return spyOnLocalsync(function() {
            var ready;
            ready = false;
            runs(function() {
              return window.dualsync('read', model, {
                success: (function() {
                  return ready = true;
                })
              });
            });
            waitsFor((function() {
              return ready;
            }), "The success callback should have been called", 100);
            return runs(function() {
              expect(window.onlineSync).toHaveBeenCalled();
              expect(_(window.onlineSync.calls).any(function(call) {
                return call.args[0] === 'read';
              }));
              expect(window.localsync).toHaveBeenCalled();
              return expect(_(window.localsync.calls).any(function(call) {
                return call.args[0] === 'read';
              }));
            });
          });
        });
      });
      describe('update', function() {
        return it('delegates to both localsync and onlinesync', function() {
          return spyOnLocalsync(function() {
            var ready;
            ready = false;
            runs(function() {
              return window.dualsync('update', model, {
                success: (function() {
                  return ready = true;
                })
              });
            });
            waitsFor((function() {
              return ready;
            }), "The success callback should have been called", 100);
            return runs(function() {
              expect(window.onlineSync).toHaveBeenCalled();
              expect(_(window.onlineSync.calls).any(function(call) {
                return call.args[0] === 'update';
              }));
              expect(window.localsync).toHaveBeenCalled();
              return expect(_(window.localsync.calls).any(function(call) {
                return call.args[0] === 'update';
              }));
            });
          });
        });
      });
      return describe('delete', function() {
        return it('delegates to both localsync and onlinesync', function() {
          return spyOnLocalsync(function() {
            var ready;
            ready = false;
            runs(function() {
              return window.dualsync('delete', model, {
                success: (function() {
                  return ready = true;
                })
              });
            });
            waitsFor((function() {
              return ready;
            }), "The success callback should have been called", 100);
            return runs(function() {
              expect(window.onlineSync).toHaveBeenCalled();
              expect(_(window.onlineSync.calls).any(function(call) {
                return call.args[0] === 'delete';
              }));
              expect(window.localsync).toHaveBeenCalled();
              return expect(_(window.localsync.calls).any(function(call) {
                return call.args[0] === 'delete';
              }));
            });
          });
        });
      });
    });
    describe('respects the remote only attribute on models', function() {
      it('delegates for remote models', function() {
        var ready;
        ready = false;
        runs(function() {
          model.remote = true;
          return window.dualsync('create', model, {
            success: (function() {
              return ready = true;
            })
          });
        });
        waitsFor((function() {
          return ready;
        }), "The success callback should have been called", 100);
        return runs(function() {
          expect(window.onlineSync).toHaveBeenCalled();
          return expect(window.onlineSync.calls[0].args[0]).toEqual('create');
        });
      });
      return it('delegates for remote collections', function() {
        var ready;
        ready = false;
        runs(function() {
          collection.remote = true;
          return window.dualsync('read', model, {
            success: (function() {
              return ready = true;
            })
          });
        });
        waitsFor((function() {
          return ready;
        }), "The success callback should have been called", 100);
        return runs(function() {
          expect(window.onlineSync).toHaveBeenCalled();
          return expect(window.onlineSync.calls[0].args[0]).toEqual('read');
        });
      });
    });
    describe('respects the local only attribute on models', function() {
      it('delegates for local models', function() {
        return spyOnLocalsync(function() {
          var ready;
          ready = false;
          runs(function() {
            model.local = true;
            window.onlineSync.reset();
            return window.dualsync('update', model, {
              success: (function() {
                return ready = true;
              })
            });
          });
          waitsFor((function() {
            return ready;
          }), "The success callback should have been called", 100);
          return runs(function() {
            expect(window.localsync).toHaveBeenCalled();
            return expect(window.localsync.calls[0].args[0]).toEqual('update');
          });
        });
      });
      return it('delegates for local collections', function() {
        var ready;
        ready = false;
        runs(function() {
          collection.local = true;
          window.onlineSync.reset();
          return window.dualsync('delete', model, {
            success: (function() {
              return ready = true;
            })
          });
        });
        waitsFor((function() {
          return ready;
        }), "The success callback should have been called", 100);
        return runs(function() {
          return expect(window.onlineSync).not.toHaveBeenCalled();
        });
      });
    });
    return it('respects the remote: false sync option', function() {
      var ready;
      ready = false;
      runs(function() {
        window.onlineSync.reset();
        return window.dualsync('create', model, {
          success: (function() {
            return ready = true;
          }),
          remote: false
        });
      });
      waitsFor((function() {
        return ready;
      }), "The success callback should have been called", 100);
      return runs(function() {
        return expect(window.onlineSync).not.toHaveBeenCalled();
      });
    });
  });

  describe('offline storage', function() {
    return it('marks records dirty when options.remote is false, except if the model/collection is marked as local', function() {
      return spyOnLocalsync(function() {
        var ready;
        ready = void 0;
        runs(function() {
          ready = false;
          collection.local = true;
          return window.dualsync('update', model, {
            success: (function() {
              return ready = true;
            }),
            remote: false
          });
        });
        waitsFor((function() {
          return ready;
        }), "The success callback should have been called", 100);
        runs(function() {
          expect(window.localsync).toHaveBeenCalled();
          expect(window.localsync.calls.length).toEqual(1);
          return expect(window.localsync.calls[0].args[2].dirty).toBeFalsy();
        });
        runs(function() {
          window.localsync.reset();
          ready = false;
          collection.local = false;
          return window.dualsync('update', model, {
            success: (function() {
              return ready = true;
            }),
            remote: false
          });
        });
        waitsFor((function() {
          return ready;
        }), "The success callback should have been called", 100);
        return runs(function() {
          expect(window.localsync).toHaveBeenCalled();
          expect(window.localsync.calls.length).toEqual(1);
          return expect(window.localsync.calls[0].args[2].dirty).toBeTruthy();
        });
      });
    });
  });

  describe('dualStorage hooks', function() {
    beforeEach(function() {
      var ready;
      model.parseBeforeLocalSave = function() {
        return new Backbone.Model({
          parsedRemote: true
        });
      };
      ready = false;
      runs(function() {
        return window.dualsync('create', model, {
          success: (function() {
            return ready = true;
          })
        });
      });
      return waitsFor((function() {
        return ready;
      }), "The success callback should have been called", 100);
    });
    return it('filters read responses through parseBeforeLocalSave when defined on the model or collection', function() {
      var response;
      response = null;
      runs(function() {
        return window.dualsync('read', model, {
          success: function(callback_response) {
            return response = callback_response;
          }
        });
      });
      waitsFor((function() {
        return response;
      }), "The success callback should have been called", 100);
      return runs(function() {
        return expect(response.get('parsedRemote')).toBeTruthy();
      });
    });
  });

}).call(this);
