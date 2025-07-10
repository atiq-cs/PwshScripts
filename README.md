### Simplicity brings Power
**Refs**
- [Design Principles](https://github.com/atiq-cs/Shell/wiki/Design-Principles)
- [Wiki Entrypoint](https://github.com/atiq-cs/Shell/wiki)

A minimal, secure and high performance shell (as if isolated) unaffected by 
numerous applications and tools installed on the system. The minimal shell 
consists of following customizations,  
- `.config/nushell/*.nu`: first level initializations mostly performed by config.nu
- `init.nu`: second level initializations

We have a single line addition at the bottom of `config.nu`,

```bash
source ~/shell/init.nu
```

which enables our point of interest: `init.nu`

By default scripts are cross platform unless a tag `OS_NAME-only` exists.  
  
Find Different type of PS Scripts,
- [Unix Only](https://github.com/atiq-cs/pwsh-scripts/search?q=unix-only)
- [Windows Only](https://github.com/atiq-cs/pwsh-scripts/search?q=windows-only)


*Notations*  
In this document,  
- Unix refers to Solaris Derivatives *(Illumos kernel based distributions) i.e., OpenIndiana*