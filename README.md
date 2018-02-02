# CIS-566-Project-2

Created infinite star room.

1. Use intersetion, union, smooth blend functions to create a pentagram shape, sdf can be adjust to arbitrary number of angles.
2. Use domain repetition to duplicate pentagram primitives and light sources inside pentagrams.
3. Use noise background to create a starsky look.
4. Pentagrams are flowing around and receiving different light effects.
5. Scatter color shader

I was planning to have different star shapes and colors within one scene, managed to have two (one is pentagram, another is cross star). However, this makes webgl really slow and no way to apply domain repetition, my webgl crashed after I tried to do this. 

## Pages
https://wanruzhao.github.io/homework-2-implicit-surfaces-WanruZhao/

## Images:
![Purple](images\/star1.PNG)![Yellow](images\/star2.PNG)![Two star](images\/twostars.png)![Star with sphere](images\/starwithsphere.png)

## References:
- [IQ SDF](http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)
- [AO and scattered color](https://www.shadertoy.com/view/Xsd3Rs)
- [Noise background](https://www.shadertoy.com/view/4lSSRw)
