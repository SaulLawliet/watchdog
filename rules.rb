# coding: utf-8

rule :ituring,
     "图灵每周半价电子书",
     "http://www.ituring.com.cn/",
     ".eve-list dl:nth-child(1) dd",
     nil

rule :ikea,
    "宜家每周优惠商品",
    "http://www.ikea.com/cn/zh/",
    "#whysection a img",
    ->(o) { o[0].set_attribute("src", "http://www.ikea.com#{o[0].get_attribute('src')}") }
