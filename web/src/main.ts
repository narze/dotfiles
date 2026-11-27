import { mount } from 'svelte';
import App from './App.svelte';
import TerminalPage from './TerminalPage.svelte';
import './style.css';

mount(location.pathname === "/terminal" ? TerminalPage : App, { target: document.getElementById('app')! });
