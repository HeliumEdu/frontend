import Cookies from "universal-cookie";
import {getEnvironment} from "./environment-utils";

const cookies = new Cookies();

export const setCookie = (name, value, options = {}) =>
    cookies.set(name, value, Object.assign({
        path: '/',
        maxAge: 604800,
        secure: getEnvironment() === 'prod'
    }, options));

export const getCookie = (name, options = {}) =>
    cookies.get(name, Object.assign({
        path: '/'
    }, options));

export const deleteCookie = (name, options = {}) =>
    cookies.remove(name, Object.assign({
        path: '/'
    }, options));
