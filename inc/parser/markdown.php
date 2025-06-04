<?php

use League\CommonMark\CommonMarkConverter;

/**
 * Renderer that treats the source as Markdown using league/commonmark
 */
class Doku_Renderer_markdown extends Doku_Renderer
{
    /** @var string collected markdown source */
    protected $md = '';

    /** @inheritdoc */
    public function getFormat()
    {
        return 'xhtml';
    }

    /** @inheritdoc */
    public function document_start()
    {
        $this->md = '';
    }

    /** @inheritdoc */
    public function cdata($text)
    {
        $this->md .= $text;
    }

    /** @inheritdoc */
    public function document_end()
    {
        $converter = new CommonMarkConverter();
        $html = $converter->convert($this->md)->getContent();
        $this->doc .= '<div class="markdown-body">' . $html . '</div>';
    }
}
