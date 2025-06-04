<?php

use dokuwiki\Debug\PropertyDeprecationHelper;

/**
 * Define various types of modes used by the parser - they are used to
 * populate the list of modes another mode accepts
 */
global $PARSER_MODES;
$PARSER_MODES = [
    'container' => [],
    'baseonly' => [],
    'formatting' => [],
    'substition' => [],
    'protected' => [],
    'disabled' => [],
    'paragraphs' => []
];

/**
 * Class Doku_Parser
 *
 * @deprecated 2018-05-04
 */
class Doku_Parser extends \dokuwiki\Parsing\Parser {
    use PropertyDeprecationHelper {
        __set as protected deprecationHelperMagicSet;
        __get as protected deprecationHelperMagicGet;
    }

    /** @inheritdoc */
    public function __construct(Doku_Handler $handler = null) {
        dbg_deprecated(\dokuwiki\Parsing\Parser::class);
        $this->deprecatePublicProperty('modes', __CLASS__);
        $this->deprecatePublicProperty('connected', __CLASS__);

        if ($handler === null) {
            $handler = new Doku_Handler();
        }

        parent::__construct($handler);
    }

    public function __set($name, $value)
    {
        if ($name === 'Handler') {
            $this->handler = $value;
            return;
        }

        if ($name === 'Lexer') {
            $this->lexer = $value;
            return;
        }

        $this->deprecationHelperMagicSet($name, $value);
    }

    public function __get($name)
    {
        if ($name === 'Handler') {
            return $this->handler;
        }

        if ($name === 'Lexer') {
            return $this->lexer;
        }

        return $this->deprecationHelperMagicGet($name);
    }
}
