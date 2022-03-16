---
title: How to write a cv in latex with moderncv template
author:
  name: Mate Hajnal
  link: https://github.com/hajnalmt
categories: [Blogging, CV, Writing]
tags: [writing, cv, latex, moderncv, gitlabicon, socialgitlab]
toc: false
pin: true
---

TLDR: Here is my new CV written in latex:

- [English CV](https://drive.google.com/file/d/1w9XPNOJqwdFYGPSs9rpwU5A90er08wni/view?usp=sharing)
- [Hungarian CV](https://drive.google.com/file/d/101Q_XXq0CKaU8eYaTHczFFJKDnnm52_-/view?usp=sharing)

The source code link on Overleaf: [Hajnal Mate CV](https://www.overleaf.com/read/jxmrjgcshztv).

### Intro

Today I stumbled upon the task to refresh my CV and I decided that as a programmer I will use latex.
I am pretty much on the opinion that a programmer shall learn Markdown and Latex, to be able to create appropriately formatted documentations.
In the era of Microsoft Word files, which I just hate by instinct, this knowledge gives you whole new world, and what could be a better to practice than writing your own CV.

### Overleaf and the Moderncv template

Previously I used Sharelatex both for my Diploma work, and my project Laboratory, which got rebranded to Overleaf, which is an online Latex documentation creater.
It has a lot of benefits to use, but the biggest is that you don't need to do the compilation by yourself, so you don't need to setup the latex related environment on your machine, which is vaguely gruesome. An other cool feature is that it provides you a lot of templates to choose from: [Overleaf templates](https://www.overleaf.com/latex/templates). 

> Search for the [CV templates](https://www.overleaf.com/latex/templates/tagged/cv) to get a nice grasp about what to choose from.
{: .prompt-tip }

Overleaf gives you these out of the box, with sharing, automatic template creation and history tracking. I went with the [Modern CV template](https://www.overleaf.com/latex/templates/modern-cv-and-cover-letter-2015-version/sttkgjcysttn) which is a little bit old template, but I liked the classical style of it.
The new trend is that the new cv-s are not containing profile pictures, which I can live with, but I decieded to include it in my CV, and the template contained one too, so its fine I guess.

To change the style from casual to classic you need to edit the `\moderncvstyle{casual}` line to classic:

```latex
\moderncvstyle{classic}
```

### Social links

After my wife choose a picture (my choice wasn't good enough, as she and my mother aggreed upon), I needed to add the availability.

Filling the E-mail, Mobile, Github, Linkedin and extrainfo part won't be too hard for you, basically you need to just insert your informations.
The hard part came, when I wanted to insert my Gitlab profile link too.

At first I tried to just add the gitlab link with the social command, but the cv then didn't compiled at all.
```latex
\social[gitlab][https://gitlab.com/hajnalmt]{hajnalmt}
```

[This post](https://tex.stackexchange.com/questions/559409/moderncv-does-not-display-gitlab-icon-only-in-classic-style) helped to understand that the modercv template doesn't know about the gitlab favicon and you need to add the symbol to the social command.
You basically need to add the fontawesome to the template and create the new social command:

{% raw  %}
```latex
% load fontawesome icons
\usepackage{fontawesome}
% set the moderncv command for the Gitlab icon
% create command if it does not exist
\providecommand*{\gitlabsocialsymbol}{}
% set command to \faGitlab from fontawesome
\renewcommand*{\gitlabsocialsymbol}{{\scriptsize\faGitlab}~}
```
{% endraw  %}

After the the template worked again and I got a nice gitlab icon next to my gitlab link.


### The rest
The rest of the document is pretty straightforward, basically you need to fill up the CV with the informations.
Be aware, that you are able to define new sections with the `\section{}` command and create new cv entry item with `\cvitem{}{}`, in the first paranthesis you can enter the year related informations and in the second one, you can enter the text itself.

> You can force a new line creation with the `\newline` command, create bold text with the `\textbf{}` and add additional space between the sections with the `\vspace{}` command.
{: .prompt-tip }

That's all, I wish happy latex usage, and cv writing for you!
