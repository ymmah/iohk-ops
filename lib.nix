# To interact with this file:
# nix-repl lib.nix

let
  # Allow overriding pinned nixpkgs for debugging purposes via iohkops_pkgs
  fetchNixPkgs = let try = builtins.tryEval <iohkops_pkgs>;
    in if try.success
    then builtins.trace "using host <iohkops_pkgs>" try.value
    else import ./fetch-nixpkgs.nix;

  pkgs = import fetchNixPkgs {};
  lib = pkgs.lib;
in lib // (rec {
  ## nodeElasticIP :: Node -> EIP
  nodeElasticIP = node:
    { name = "${node.name}-ip";
      value = { inherit (node) region accessKeyId; };
    };

  centralRegion = "eu-central-1";
  centralZone   = "eu-central-1b";

  ## nodesElasticIPs :: Map NodeName Node -> Map EIPName EIP
  nodesElasticIPs = nodes: lib.flip lib.mapAttrs' nodes
    (name: node: nodeElasticIP node);

  resolveSGName = resources: name: resources.ec2SecurityGroups.${name};

  orgRegionKeyPairName = org: region: "cardano-keypair-${org}-${region}";

  inherit fetchNixPkgs;

  traceF   = f: x: builtins.trace                         (f x)  x;
  traceSF  = f: x: builtins.trace (builtins.seq     (f x) (f x)) x;
  traceDSF = f: x: builtins.trace (builtins.deepSeq (f x) (f x)) x;

  # Parse peers from a file
  #
  # > peersFromFile ./peers.txt
  # ["ip:port/dht" "ip:port/dht" ...]
  peersFromFile = file: lib.splitString "\n" (builtins.readFile file);

  # Given a list of NixOS configs, generate a list of peers (ip/dht mappings)
  genPeersFromConfig = configs:
    let
      f = c: "${c.networking.publicIPv4}:${toString c.services.cardano-node.port}";
    in map f configs;

  # modulo operator
  # mod 11 10 == 1
  # mod 1 10 == 1
  mod = base: int: base - (int * (builtins.div base int));

  # Developer keys:
  #
  alanKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBg0dSLJhcG3NtAHwi70UvdsQDy0EzDBmIfbPT2Bi2Aq4kicc3iy6vRduAOFgogdeXSL0ML5DD0KAyxgAo8aOVcGNLqsbfvhDwaQjqTjDS1twy7ZysmoFTKMfQT8k/Qs3GjL4ycEiibweJKvRHU2or7/3t+Owvu3yC56uADg4WpP2VThwACzJbwt39VKmEnf3fpxpXZ2s4/Y8bLpG/8XC0/PBbgSbgj7p5ksPAeJOCNSbhq8/NlGPOeoR/puVobX7HVwf/nfn/Jnsqzx4oZ8cuK9zM5GBi6VQ43awGsXXiTmSW57ql3M6lmBGuZOArSfYIY7PsUSQukqeoGA6E/t1r Alex Vieth";
  dshevchenkoKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8UtxHIGffqg76zqzAfAvO9CC9cgae66qcm4rjb26OGQzBewqN3cvh32U75d7UF6agXLr7O6RAF1L23G2vyJ+xuEK9zFXnbhCIoyOVnnwrNGNPqFLlDAcPwlBtaDjobJE2xYlOqgRFIzOfQa/43zr6yk696bVCk/9jjaJLWIhPJ9/BMTJ1KOcsaZB6GfHoDMICIAkFRb9Qgvq3rHy185nQP7v+olxuMRjhfrkAuUi8tZSN0Vz5DYKNBc9lgBeWXzdpI/pcaXMK7CW5GGdHUpC4S4GMtWwiii//NeVhiyHkbdHQo0pF+0w82fZOovBH5jLxtlY45kJ3nrk2a9eo0LuH dshevchenko@MacBook-Pro-Sevcenko.local";
  larsKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AM6TDijvz2LlW4OVJXFFoiPwtxUg47861kZgwQbUpgWRAC1er81KZrF7532x6/+MO1WyO29ckdwaVRNL7M04JQDNsVRNhwl6H32rZqdBpxvnSZce4LeR0yasddFpkQmnqB2AxiNmECkw4gbxHgaSLv59pi6vPTKihNlaxK338MkuwtorcO3eJ1NB0Ap2Cl+oBO8E9eDuhArFdWwX4BhqVwIWSI7KNzj+jNavO2qyjfr1CsJpc3qJLQEdX0Oy3VSFykSvSDsk5uldcv4eglgBLNSq9qiZ0K2WlYM+BZOUdVV6bQUq+WQdLX5siEy+ZLwhACSZ3PxTgynRY3BWrWIVsyWClAWixGedz6BBeNZekGymnrcy7ncQ3F1+Vgjhtld9qmLjQYxR4/fKTKT0LtG3aDYmv9gnlwqbenNepiefRsbVYhrsuX4meHg3CUmAc40tYASPghqpKxY+BM0QwXDLQD0qzbhzGzRmASkxFcvmgEzfXlVASvFduqZPRUoKOTiUiV6aVlPQewY81BevT6SB76GM4XqArfExqHKb3S/5cnLO+8tzoxxnRMbI846rSZzh5mNYPp2SDCrvbAkbxWGxlrPJgyZWC/QlGaWCju4pzLzTpVxs1X461NPzUetdc15IlGq44QNSHHM8sIYd2GA2d8khmplPW5UFVPwpk0emcQ== brunjlar@gmail.com";
  philippKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDe56RW9j9Fj4r/yCXX+zjNh8qRjyC6DnnwAubTssganiRuCX2gIwSS4cdncXVIEnYY+T7PLv4rW7tooNL0qiBjBnLHTuvh6ibq/d3RpzCDbjpl377T16yh7wQ/Pj6yOb4xYof0fW3OLRKxK2wLqtKdmVAEfwGNxN6uIAThhk8g6+5xPyZFzRimRuMiV+vl0PPHDd1YHDuJEvt1LRuMILDtbEHHxFhO08haVCti0TthbkeTMrvG0nPCGCzh5Xy95w0QhbmgUmLevmVBexHsT4FAHI5M1DirHz9PwkXbxPIumcy0Z31dZ6JCexTTvtvPQllkC9k98VHVzd/Y24gGUaDV philipp@philipps-mbp.fritz.box";
  ksaric = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsXWw3gV6QSH19yE/wNSie+e9lcJ01kfSacEUtqkLJpV5DrhaPJ6P73c8olV3AkysmJdaMMPzaf34Q62suo0baHQPxjvZL9dXcEKPeO98EUtU6cDUclIVRQKD2zit/6hNy1EeHpaRufjzuJCoWWDhp0n17TSNcWx05UOi5W3ZWmRw4hzQLj0fJ4+DS4iNhWKGei4SeUI1XkOg7o1Rg3ODdg5hpzQx9AWy7RfO8MJoXqdjEwbhIE+rzfiXiuClCBH+uNvtNNqEp0gqtsOU3qSyn65OLVA1M3pDHQGe+xQQnJYHRVLAKFWK9Ft6YKnJZLczmgZJ85PRydLbtWPzo34ax ksaric@ksaric-H61M-S2V-B3";
  akegaljKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCn11qMrU3M+k/S5ScA8C37pPB7XNxzOmBnF89NkjJ16JhZxlX5tqEfq2Arja+nEG6UB8Js/5MsWTRkVYK6pB+ju0RAb5qyYomU/zZBhf9yOLlWuXTCV1ptdwRxLptjRdJ9a9YC0q715ZnNoIhfbVoR8o/CYLBFKFdFcV8O87R6mWPJ1I2CgTtfW3zjlFD8xRXtirio5EzNaq/Tq4ClQdpAOlfwHErxfk/TQMFY7vLiBdd26YEn+zD95xF4EX9cT7A2BHFD3U7OioTOTiyRwhaP3dFPcy+51fKGvxhBXtdb0fu+OanjQjsezmnBXwzSprKJUj6VjFoB4yt5qHqj0ntx akegalj@gmail.com";
  alfredoKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsD6QElYU5ubuUsgLmQh4/PI8ltKiBpmVCGSSV0dQ6h alfredo.dinapoli@iohk.io";
  vasilisKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1mLZOMObZH/75UF8+UzfURT+OpVrSfwb3Uj2PoY9UTXUOVKSwxs/i7jLRvawIHShpKBTi/P2BuTtCXc9FMv1pWiIUTCR/1P5ti6xnysyyUW5h5VOSeTZU+Sxyo590QrEW+9dMUyOS+rg/FaJI0DzkhI6UFq5E8vzQB/N5U9bmlYhxfFvGP4Jea4YaanrJRnqXMseINQUHn66IC6yBmzBIEEMWQmQ6D/u6dykJYkPf1o4Kh1W3VfcpUc1Ijrx+AW6jmszwhJjjNKII2et4FIsIuhwxz9JcA5ERurCAAIMxnZG9ZtFkXZMy3QQ8Ss3gwUVXHcTKNlbGUezhynD1aoDT vagoum@riemann";
  andreasKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+jXbzao695RgcORzsfMZIUjaE802hTv3YkN4oRQUa5Ucninw/ngaPMI0Ym8IKCW7N9B40lOOZuIiGv2zEL6Y55/vUS7Y9hBX4vlB0qLC75+rj80JHyc8zEMBPNNrR3j+EXvWadCx0EYIEV9DsqkLNrUOtweqkPOfA4IUypX1xVmaPpUsqXTThjy8z4jJPgFhN6wVDRQ66WNzMjFwt1B9X11jNUy0WLP2idzqLoko/gkZiNOslJVWniOzeHiPrHOmiEWEj1xSaZ05r1FeJR/UKYuKQQ1sZEoqeXM4BgRDjqpJN/+AtCIC8CTltRu3WVMfpiwma5BAA2Nbbe5rc8xACgZvzJLtADJLCyyhRzVeOhW0c9t9RcG1zafaLJ81VBSrpPog0pcT4C/CHmgveti0OAY7uNATsRq6Nm6fGaXLzsRdOjtytS7JEVb11ZMUbDLTlj/uu0RSzrtmDdLbsS1X/7BHrnd9Q4XKS0RJVLjDmi4htdLSZF1675g7ZhZGSu3sMP6IGUIsE0QrPSKuybWBWnkJqP5ytqbxMolK0AziIbgjKOE1DBR24IBQaFhhGPjAErPy2wGLpMdc6Dfnq481d7xzR4Cxz2fqU7P5cISZklHc86F6K/gqdR+ucSFdHl7lPU3jmxGe1pU1+AznCDJ8g1ZOBeLGyJUbNI6kVPoWTCw== andreas_triantafyllos@hotmail.com";
  alexandersKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUGnVIJ5w4OP9RaTZKM929Wt69UyvbBLyK65FNAkNXraKJ4t7rp41AaiY17byBET5vHxiF7CdVxi2nng6SQKp8VOlCPvF/AN4ZjruFDIXunJLERzf7GCR+bQPu4E/uj1hR9lIs8/jRKtHN6cZ7jcRni8b7BSIISInHTDwGm7XhdpRQlrxMK67oMXQuuOnEEShmH+ER0ICGk/o33SIAK2bebfRgCdI7N8iMZ/vw9ACHptN1wG70H2OVZADFY7J2mS0EFz+iFx5aOn/EbQfgNb8y9+K4+kfWxl/lwFw0Lj6YwUMEvqlqtHRYKq7uLT18JzYfM4mtGkYaNGDmzfqqpq5UTIW0txr9luNf5CRZeJctsY/OpxV1dPZXIMMENl1Y3a2GnD2YfKZ04eQrUgFN4R5J9S3dhkqUNlzc72/dkbCbWVk86+uG4k+DAm5MCua9xaF7jEuwd/BnCw72ce06hf5soyiIpOLhkuMyTY6/rXiSYETdGlJKTgx1S3bqa5FD4yXA++fwxoOLww/ZMRRdiufSk3KJBvAQMP0lKxR7uQA9S4ZGzLifWII21f2x1mLvknzzhKY4hZLmXA/TIeeygWYmIF5ldoTVtWP6duLspFzC3Fei+tm6ZzYcuuAX6jaT76Kkrsy9bQOjuI/mwwILzD6qZeu41Y/FsvQzgVqJ91HX/w== codieplusplus@apax.net";

  devKeys = devOpsKeys ++ [ alanKey dshevchenkoKey larsKey philippKey ksaric akegaljKey alfredoKey vasilisKey andreasKey alexandersKey ];

  devOpsKeys = [ jakeKey jakeKey2 kosergeKey michaelKey rodneyKey samKey ];

  # DevOps keys:
  #
  jakeKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkmQINS+6ho3cI/Du2XDGYud23BKcvjcOD8XigxDfHxA17QUgVlgTZZL+/Gat3lSPQ/Pjs3FBv0SmENhhtVIevXCglMrUocr+mWDERjmUnWw2ZsR6RvEVbhyzwe6f89VnmVfcLBNgDZTJu/Yj4W6WY5hXLcFjQzCyXLwoCc4+5z+jSO+D5V8Ht10slngx3gKUx/Wx1G0CtTT7VI405JHZxgMc7iASREwN3dfCPxEUvn09Lb2yUEljAs+BOLCPnv9JWDnwhg6Iswzq0f4ORx7KNrT2NqBPl/4CxNWtyYYFRzRy/aD+u/dUJm3ZV+6xgTOI1jXIc5BrEHx4otwvV4+wZ jacob.mitchell@iohk.io";
  jakeKey2 = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCHp7NG8/2sNlgQfNA5+8A1KA/u/ioaapw87MpExUj+UxM9pBLuB3mFjDlOSSi5j4IzdtL6ArHNLNM44hcNvH/LbcaQlSUe9/a+I8v0sSFWLPrrAzB26AjZjMKKeOx7QnDY2WKRYeUAv8yM7cYh4GErfzh3qZaUY0zoJpx2beNLkLMjjyfCRfQKaZVzrzUb82KucLv/3wmNwh+w7nUzQGkWfujcQ/g/SPdmwgejf4HtJkMTgRMymLab7HGHnpvKx+6DN+Z8pDgT2aXu+x+MEDw9TaxXkJYZmvZq1+4wTcR1UPmxkY8wfBLR+IXGIL5oBgz/El8Rhp+4iEAW2AN7r/P jacob.mitchell@iohk.io";
  kosergeKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDwRtXm1TviRRjstPHV6G+to0P7lhN5F4Za5fMxva9MbY3XequPBBU5/HjoyZUTcZYN7bVlh9TFLQW6GrwYtL8g6W7+qj9vjZAT+pdrnpLgN+mGXppzsIbe8SZdLj11+nrL+jr1EBDnu4CmIeGfGCeKmQdYcXHBxDOYUxl80Qqjw4SKzLCWa0NAiJPaO+O1BQ1gjjDSTGumTq/DFtYi0yCjhhgXRKLQFZeOc4eV3uUXzqqwKb8i89sUFNIxPnZgEpMC5IX33r8+9CcibhDvFXxhCbEhwyxAlygzJCdntwRzIigOHxBiZV+KW9nRy/sUUC/82zB6BHZPdYV9Gb3r2740BR5jTac9Qps7MkaGuFANDkjy4ASC9DiL3TGoWjiScF100kbHsBDnEqzsybQrDXxpgTd8PiqZq9I1l1as2UoeuR3IPHO7zBbgbCy4rv9a7ZeITsPT7HcRDGHsVT762KnxVxQnR3m0CpoKGKWOKngMVRCTYsQ7Ng7f/ade9isduccrMeeTjGdkeC8QGS4VnfIEEqfHPJBS8/nree40vpvtWsvKHM346GQRm6A2UI14yBZIr/SoLQEZZP3TGwcOAA4Ze3BNGjPT38gnrPO3M8HiUJCyK3RS8GMOVr2K35aS+YTKOkLRYt4vM+vwSIWLtNgjq5kXh3HHOwFAWFn2m+ZBw== koserge-2017-04";
  michaelKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbtjKqNiaSVMBBSK4m97LXCBwhHMfJh9NBGBxDg+XYCLOHuuKw2MsHa4eMtRhnItELxhCAXZg0rdwZTlxLb6tzsVPXAVMrVniqfbG2qZpDPNElGdjkT0J5N1X1mOzmKymucJ1uHRDxTpalpg5d5wyGZgwVuXerep3nnv2xIIYcHWm5Hy/eG0pRw6XuQUeMc3xSU5ChqZPwWqhdILkYteKMgD8vxkfmYE9N/2fPgKRmujKQ5SA0HoJYKBXo29zGQY5r6nt3CzuIANFD3vG3323Znvt8dSRd1DiaZqKEDWSI43aZ9PX2whYEDyj+L/FvQa78Wn7pc8Nv2JOb7ur9io9t michael.bishop";
  rodneyKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC9soUucXq/jZvm4u5a49m+aB2+l1w8VRyrjcjMGHZslHZYtMuI6vNJ9AsK+cFEirq888ITa/ucriMInukvzP3WCRthvWgPINsbupOpaHxX0k6N2RRYZQbSeKMzjhnoIkM1GkrjHuRAEjUN4RbcbEzhgVGranb8+Mb6UIkFfCwgJJdzX8X9QWStVoUsO7C+x8+m1cYkxdWYrpGqyXZ+g9P7K2rKlfoz4kEAyo4Mivh8+xmO7bPSLpGuBgM7bt4Yyaq1YSuLOp5f5P4Nsa5MmXKANumEZqVNzgLlommB/3xr7N6q+K1nLt/OxvrxrNVMpwL/TYmTRGQ/UVQziglCQz1p rodney@aurora";
  samKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5PPVdfBhmWxWYjSosuyjMdIYNjYC/ekz+Whv27wrFNHqxeGgKbXslUTwZX0r+zu/nlJnX9nj3zdVV9LosBB8JF9tfJGui9aBfPuxoIq9SMFSdcpZ8aOh4ZITv7zbsRHMECE8q7D5/a+7UZyTy8pv9g5SuCerHh3m//NIbo08OS9rt8SjqVio+B+rseLF960U3U3wTCtOA+VauTuE4kZfSfmQlEYUjaN3qwp4s5jpO7pgnGxshuqayRyuwJfRa/RYWB5ouSjyxTuo33K42EqT4XFoURkj7evJB5SRR7pm4vJCx4VkclIVmpLIcBiyWje+60zyKhAZEQVqKXedkuQ9748wZl07C6Czs4QiloGAjXv/tRm9YSdoeG5JhskEA8z2SCEQARJGquPH+f5vBltHeVC5K5LW94gSP9bfVBitcCgONVxUguCu0PmJUYKcVVjRi3KtJJzDSTDCjjN3e/mszrZY921yvVEkb7mFATBiHeSdrt55gKcG1vfTToLALIJJFQpGCwAMYUjKEcgq4PZa1UdCY/ynvynLds3mge4Y/X3EnLFsJaepfgNyPnnPg67kEda8uRSDYT8LaoqJpDzc7RQeY4BOfJfAxa8qMDHmp4W+dxHqrMphbH66fwUJAx1MWV8AoPFW0TGrDb3AnHBgoRt/5Fnz2ymy92Wb1KAIt3w== sam@optina";
})
