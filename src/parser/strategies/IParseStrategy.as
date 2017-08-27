package parser.strategies {
import flash.utils.Dictionary;

public interface IParseStrategy {
    function execute(externalContext:String = "this"):IParseStrategy;
    function get externalImportsHashList():Dictionary;
    function get externalConstructor():String;
    function get externalVariables():String;
    function get type():String;
}
}
