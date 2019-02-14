from moja_py import PyModule
from random import randint

class VarSetter(PyModule):
    def onTimingInit(self):
        var = self.getVariable("pyvar")
        var.set_value(randint(0, 100))

class VarGetter(PyModule):
    def onTimingShutdown(self):
        var = self.getVariable("pyvar")
        print(var.value())

modules = {
    "VarSetter": VarSetter,
    "VarGetter": VarGetter
}
