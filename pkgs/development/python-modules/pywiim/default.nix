{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,

  # deps
  aiohttp,
  pydantic,
  async-upnp-client,
  m3u8,
  mutagen,

  # dev dependencies
  black,
  isort,
  ruff,
  mypy,
  pytest,
  pytest-asyncio,
  pytest-cov,
  pytest-xdist,
  pyyaml,

  # mcp deps
  mcp,
}:
buildPythonPackage rec {
  pname = "pywiim";
  version = "2.3.7";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mjcumming";
    repo = "pywiim";
    rev = "v${version}";
    hash = "sha256-ORAC/94C8Q/ASr8qZmRQg2tlc46G4nLJg9+EHgJwGQ0=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    aiohttp
    pydantic
    async-upnp-client
    m3u8
    mutagen
  ];

  optional-dependencies = {
    mcp = [
      mcp
    ]
    ++ mcp.optional-dependencies.cli;
  };

  nativeCheckInputs = [
    pytestCheckHook

    # dev dependencies
    black
    isort
    ruff
    mypy
    pytest
    pytest-asyncio
    pytest-cov
    pytest-xdist
    pyyaml
  ]
  ++ optional-dependencies.mcp;

  pythonImportsCheck = [ "pywiim" ];

  meta = with lib; {
    description = "Python library for WiiM/LinkPlay device communication";
    homepage = "https://github.com/mjcumming/pywiim";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with lib.maintainers; [ tebriel ];
  };
}
